import SwiftUI
import SwiftData

struct RecipeCollectionView: View {
    @Query private var dishes: [Dish]
    @State private var searchText = ""
    @State private var filterKind: DishKind? = nil

    private var filtered: [Dish] {
        dishes
            .filter { !$0.menuName.isEmpty }
            .filter { filterKind == nil || $0.kind == filterKind }
            .filter { searchText.isEmpty || $0.menuName.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.menuName < $1.menuName }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // フィルタータブ
                filterBar

                if filtered.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List(filtered) { dish in
                        NavigationLink(destination: DishEditView(dish: dish)) {
                            RecipeRow(dish: dish)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("レシピ集")
            .searchable(text: $searchText, prompt: "メニュー名で検索")
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "すべて", isSelected: filterKind == nil) {
                    filterKind = nil
                }
                ForEach(DishKind.allCases, id: \.self) { kind in
                    FilterChip(label: kind.rawValue, isSelected: filterKind == kind) {
                        filterKind = (filterKind == kind) ? nil : kind
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) { Divider() }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(label, action: action)
            .font(.system(size: 13))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? Color.primary : Color.clear)
            .foregroundStyle(isSelected ? Color(.systemBackground) : Color.secondary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.secondary.opacity(0.3), lineWidth: 0.5))
    }
}

struct RecipeRow: View {
    let dish: Dish

    var body: some View {
        HStack(spacing: 12) {
            // サムネイル
            if let photo = dish.photos.sorted(by: { $0.sortIndex < $1.sortIndex }).first,
               let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.tertiary)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(dish.menuName)
                    .font(.system(size: 15))
                HStack(spacing: 6) {
                    DishKindTag(kind: dish.kind)
                    if !dish.ingredients.isEmpty {
                        Text("材料 \(dish.ingredients.count)品")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
