import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WeekListView()
                .tabItem {
                    Label("週間", systemImage: "calendar")
                }
            IngredientSummaryView()
                .tabItem {
                    Label("食材集計", systemImage: "cart")
                }
            RecipeCollectionView()
                .tabItem {
                    Label("レシピ集", systemImage: "book")
                }
        }
    }
}
