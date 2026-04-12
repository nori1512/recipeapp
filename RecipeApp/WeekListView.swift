import SwiftUI
import SwiftData

struct WeekListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Week.sortIndex) private var weeks: [Week]
    @State private var selectedWeekIndex = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 週タブ
                weekTabBar

                // 曜日カードリスト
                if weeks.isEmpty {
                    emptyState
                } else {
                    let week = weeks[min(selectedWeekIndex, weeks.count - 1)]
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(week.sortedDays) { day in
                                DayCard(day: day)
                            }
                        }
                        .padding(16)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("夕食レシピ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        addWeek()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                if weeks.isEmpty { seedInitialWeeks() }
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
                    .background(
                        selectedWeekIndex == i
                            ? Color.primary
                            : Color.clear
                    )
                    .foregroundStyle(
                        selectedWeekIndex == i
                            ? Color(.systemBackground)
                            : Color.secondary
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView(
            "週を追加してください",
            systemImage: "calendar.badge.plus",
            description: Text("右上の＋ボタンで週を追加できます")
        )
    }

    // MARK: - Data helpers

    private func seedInitialWeeks() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // 月曜日を起点に5週分
        let monday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        for i in 0..<5 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: i, to: monday) ?? monday
            createWeek(startDate: weekStart, index: i)
        }
        try? context.save()
    }

    private func addWeek() {
        let newIndex = weeks.count
        let calendar = Calendar.current
        let base = weeks.last?.startDate ?? Date()
        let nextStart = calendar.date(byAdding: .weekOfYear, value: 1, to: base) ?? base
        createWeek(startDate: nextStart, index: newIndex)
        try? context.save()
        selectedWeekIndex = newIndex
    }

    private func createWeek(startDate: Date, index: Int) {
        let week = Week(startDate: startDate, sortIndex: index)
        context.insert(week)
        for dayIndex in 0..<5 {
            let day = Day(weekdayIndex: dayIndex)
            day.week = week
            context.insert(day)
            for kind in DishKind.allCases {
                let dish = Dish(kind: kind)
                dish.day = day
                context.insert(dish)
            }
        }
    }
}

// MARK: - DayCard

struct DayCard: View {
    let day: Day
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text(day.weekdayName)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .overlay(alignment: .bottom) { Divider() }

            // 料理行
            ForEach(DishKind.allCases, id: \.self) { kind in
                if let dish = day.dish(for: kind) {
                    DishRowSwipeable(dish: dish, onClear: {
                        clearDish(dish)
                    })
                    if kind != .soup { Divider().padding(.leading, 14) }
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }

    // メニュー名・材料・メモ・写真・リンクをすべてクリア
    private func clearDish(_ dish: Dish) {
        dish.menuName = ""
        dish.memo = ""
        dish.ingredients.forEach { context.delete($0) }
        dish.photos.forEach { context.delete($0) }
        dish.links.forEach { context.delete($0) }
        try? context.save()
    }
}

// MARK: - DishRowSwipeable

struct DishRowSwipeable: View {
    let dish: Dish
    let onClear: () -> Void

    var body: some View {
        NavigationLink(destination: DishEditView(dish: dish)) {
            DishRow(dish: dish)
        }
        .buttonStyle(.plain)
        // 内容が入っているときだけスワイプ削除を有効にする
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !dish.menuName.isEmpty {
                Button(role: .destructive, action: onClear) {
                    Label("クリア", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - DishRow

struct DishRow: View {
    let dish: Dish

    var body: some View {
        HStack(spacing: 10) {
            DishKindTag(kind: dish.kind)
            if dish.menuName.isEmpty {
                Text("未入力")
                    .font(.system(size: 14))
                    .foregroundStyle(.tertiary)
                    .italic()
            } else {
                Text(dish.menuName)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - DishKindTag

struct DishKindTag: View {
    let kind: DishKind

    var body: some View {
        Text(kind.rawValue)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(bgColor.opacity(0.15))
            .foregroundStyle(bgColor)
            .clipShape(Capsule())
    }

    private var bgColor: Color {
        switch kind {
        case .main: return .blue
        case .side: return .green
        case .soup: return .orange
        }
    }
}
