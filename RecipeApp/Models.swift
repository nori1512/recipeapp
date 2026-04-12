import SwiftData
import Foundation

// MARK: - Week

@Model
class Week {
    var startDate: Date
    var sortIndex: Int
    @Relationship(deleteRule: .cascade) var days: [Day] = []

    init(startDate: Date, sortIndex: Int) {
        self.startDate = startDate
        self.sortIndex = sortIndex
    }

    var label: String {
        "第\(sortIndex + 1)週"
    }

    var sortedDays: [Day] {
        days.sorted { $0.weekdayIndex < $1.weekdayIndex }
    }
}

// MARK: - Day

@Model
class Day {
    var weekdayIndex: Int   // 0=月, 1=火, 2=水, 3=木, 4=金
    var week: Week?
    @Relationship(deleteRule: .cascade) var dishes: [Dish] = []

    init(weekdayIndex: Int) {
        self.weekdayIndex = weekdayIndex
    }

    var weekdayName: String {
        ["月曜日", "火曜日", "水曜日", "木曜日", "金曜日"][weekdayIndex]
    }

    var weekdayShort: String {
        ["月", "火", "水", "木", "金"][weekdayIndex]
    }

    func dish(for kind: DishKind) -> Dish? {
        dishes.first { $0.kind == kind }
    }
}

// MARK: - Dish

enum DishKind: String, Codable, CaseIterable {
    case main  = "主菜"
    case side  = "副菜"
    case soup  = "汁物"
}

@Model
class Dish {
    var kindRaw: String
    var menuName: String
    var memo: String
    var day: Day?
    @Relationship(deleteRule: .cascade) var ingredients: [Ingredient] = []
    @Relationship(deleteRule: .cascade) var links: [RecipeLink] = []
    @Relationship(deleteRule: .cascade) var photos: [RecipePhoto] = []

    init(kind: DishKind, menuName: String = "") {
        self.kindRaw = kind.rawValue
        self.menuName = menuName
        self.memo = ""
    }

    var kind: DishKind {
        get { DishKind(rawValue: kindRaw) ?? .main }
        set { kindRaw = newValue.rawValue }
    }

    var sortedIngredients: [Ingredient] {
        ingredients.sorted { $0.sortIndex < $1.sortIndex }
    }
}

// MARK: - Ingredient

@Model
class Ingredient {
    var name: String
    var amount: String
    var sortIndex: Int
    var dish: Dish?

    init(name: String = "", amount: String = "", sortIndex: Int = 0) {
        self.name = name
        self.amount = amount
        self.sortIndex = sortIndex
    }
}

// MARK: - RecipeLink

@Model
class RecipeLink {
    var url: String
    var title: String
    var serviceType: String   // "youtube" | "instagram" | "cookpad" | "other"
    var dish: Dish?

    init(url: String, title: String = "", serviceType: String = "other") {
        self.url = url
        self.title = title
        self.serviceType = serviceType
    }

    static func detect(from urlString: String) -> String {
        let s = urlString.lowercased()
        if s.contains("youtube.com") || s.contains("youtu.be") { return "youtube" }
        if s.contains("instagram.com") { return "instagram" }
        if s.contains("cookpad.com") { return "cookpad" }
        return "other"
    }
}

// MARK: - RecipePhoto

@Model
class RecipePhoto {
    var imageData: Data
    var sortIndex: Int
    var dish: Dish?

    init(imageData: Data, sortIndex: Int = 0) {
        self.imageData = imageData
        self.sortIndex = sortIndex
    }
}

// MARK: - IngredientSummary (computed, not stored)

struct IngredientSummary: Identifiable {
    let id = UUID()
    var name: String
    var amounts: [String]

    var displayAmount: String { amounts.joined(separator: " + ") }
}
