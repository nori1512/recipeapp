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
            // 初期Dishは生成しない（ユーザーが自由に追加）
        }
    }
}

// MARK: - DayCard

struct DayCard: View {
    let day: Day
    @Environment(\.modelContext) private var context
    @State private var showAddSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text(day.weekdayName)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if day.sortedDishes.isEmpty {
                // 料理未登録のとき
                Button {
                    showAddSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                        Text("料理を追加")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
            } else {
                Divider().padding(.horizontal, 0)
                // 料理行
                ForEach(Array(day.sortedDishes.enumerated()), id: \.element.id) { index, dish in
                    NavigationLink(destination: DishDetailView(dish: dish)) {
                        DishRow(dish: dish)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            context.delete(dish)
                            try? context.save()
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                    if index < day.sortedDishes.count - 1 {
                        Divider().padding(.leading, 14)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .sheet(isPresented: $showAddSheet) {
            AddDishSheet(day: day)
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
        case .staple: return .brown
        case .main:   return .blue
        case .side:   return .green
        case .soup:   return .orange
        case .other:  return .purple
        }
    }
}

// MARK: - AddDishSheet（料理追加シート）

struct AddDishSheet: View {
    let day: Day
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selectedKind: DishKind = .main
    @State private var menuName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("種類") {
                    Picker("種類", selection: $selectedKind) {
                        ForEach(DishKind.allCases, id: \.self) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
                }
                Section("メニュー名（任意）") {
                    TextField("例：ご飯、鶏の照り焼き", text: $menuName)
                }
            }
            .navigationTitle("料理を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") { addDish() }
                        .fontWeight(.medium)
                }
            }
        }
    }

    private func addDish() {
        let newIndex = day.dishes.count
        let dish = Dish(kind: selectedKind, menuName: menuName, sortIndex: newIndex)
        dish.day = day
        context.insert(dish)
        try? context.save()
        dismiss()
    }
}
