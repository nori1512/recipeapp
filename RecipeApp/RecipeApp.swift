import SwiftUI
import SwiftData

@main
struct RecipeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Week.self, Day.self, Dish.self, Ingredient.self, RecipeLink.self, RecipePhoto.self])
    }
}
