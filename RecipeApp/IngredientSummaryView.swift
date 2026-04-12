import SwiftUI
import SwiftData

struct IngredientSummaryView: View {
    @Query(sort: \Week.sortIndex) private var weeks: [Week]
    @State private var selectedWeekIndex = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 週タブ
                weekTabBar

                if weeks.isEmpty {
                    ContentUnavailableView("データがありません", systemImage: "cart")
                } else {
                    let week = weeks[min(selectedWeekIndex, weeks.count - 1)]
                    let grouped = groupedIngredients(for: week)

                    if grouped.isEmpty {
                        ContentUnavailableView(
                            "食材が登録されていません",
                            systemImage: "cart.badge.plus",
                            description: Text("週間タブでレシピの材料を入力してください")
                        )
                    } else {
                        List {
                            ForEach(grouped.keys.sorted(), id: \.self) { category in
                                Section(category) {
                                    ForEach(grouped[category] ?? []) { item in
                                        HStack {
                                            Text(item.name)
                                            Spacer()
                                            Text(item.displayAmount)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.secondary)
                                        }
                                        .font(.system(size: 14))
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("食材集計")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !weeks.isEmpty {
                        ShareLink(
                            item: summaryText(for: weeks[min(selectedWeekIndex, weeks.count - 1)]),
                            preview: SharePreview("食材集計")
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Week tab bar

    private var weekTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(weeks.indices, id: \.self) { i in
                    Button(weeks[i].label) {
                        selectedWeekIndex = i
                    }
                    .font(.system(size: 13))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(selectedWeekIndex == i ? Color.primary : Color.clear)
                    .foregroundStyle(selectedWeekIndex == i ? Color(.systemBackground) : Color.secondary)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.secondary.opacity(0.3), lineWidth: 0.5))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: - Aggregation

    /// 食材名をキーに量を集約し、カテゴリ別にグルーピング
    private func groupedIngredients(for week: Week) -> [String: [IngredientSummary]] {
        var nameAmountMap: [String: [String]] = [:]

        for day in week.days {
            for dish in day.dishes {
                for ing in dish.ingredients where !ing.name.isEmpty {
                    let key = ing.name.trimmingCharacters(in: .whitespaces)
                    nameAmountMap[key, default: []].append(ing.amount)
                }
            }
        }

        // ここではカテゴリ自動分類（簡易キーワードベース）
        let summaries = nameAmountMap.map { IngredientSummary(name: $0.key, amounts: $0.value) }
        var result: [String: [IngredientSummary]] = [:]
        for s in summaries {
            let cat = category(for: s.name)
            result[cat, default: []].append(s)
        }
        // 各カテゴリ内を名前順にソート
        for key in result.keys {
            result[key]?.sort { $0.name < $1.name }
        }
        return result
    }

    private func category(for name: String) -> String {
        let meat = ["鶏", "豚", "牛", "肉", "魚", "鮭", "タラ", "エビ", "イカ", "ツナ", "ベーコン", "ハム", "ソーセージ"]
        let veg  = ["玉ねぎ", "じゃが", "にんじん", "大根", "白菜", "キャベツ", "ほうれん草", "小松菜", "もやし", "ねぎ", "長ネギ", "きのこ", "しめじ", "えのき", "トマト", "なす", "ピーマン", "ブロッコリー"]
        let season = ["醤油", "みりん", "酒", "砂糖", "塩", "味噌", "酢", "ごま油", "オリーブ", "ケチャップ", "マヨネーズ", "ソース", "出汁", "だし", "コンソメ", "鶏がら"]

        if meat.contains(where: { name.contains($0) }) { return "肉・魚" }
        if veg.contains(where:  { name.contains($0) }) { return "野菜" }
        if season.contains(where: { name.contains($0) }) { return "調味料" }
        return "その他"
    }

    private func summaryText(for week: Week) -> String {
        let grouped = groupedIngredients(for: week)
        var lines = ["\(week.label) 食材集計"]
        for cat in grouped.keys.sorted() {
            lines.append("\n【\(cat)】")
            for item in grouped[cat] ?? [] {
                lines.append("・\(item.name)：\(item.displayAmount)")
            }
        }
        return lines.joined(separator: "\n")
    }
}
