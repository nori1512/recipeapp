import SwiftUI

struct DishDetailView: View {
    let dish: Dish
    @State private var showEditSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 未入力の場合
                if dish.menuName.isEmpty {
                    emptyState
                } else {
                    // 写真
                    if !dish.photos.isEmpty {
                        photoSection
                    }
                    // 材料
                    if !dish.sortedIngredients.isEmpty {
                        ingredientSection
                    }
                    // 作り方
                    if !dish.sortedSteps.isEmpty {
                        stepSection
                    }
                    // リンク
                    if !dish.links.isEmpty {
                        linkSection
                    }
                    // メモ
                    if !dish.memo.isEmpty {
                        memoSection
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(dish.menuName.isEmpty ? dish.kind.rawValue : dish.menuName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Text("編集")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            DishEditView(dish: dish)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("まだ入力されていません")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            Button {
                showEditSheet = true
            } label: {
                Text("レシピを入力する")
                    .font(.system(size: 15, weight: .medium))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - 写真セクション

    private var photoSection: some View {
        let photos = dish.photos.sorted { $0.sortIndex < $1.sortIndex }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(photos) { photo in
                    if let uiImage = UIImage(data: photo.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - 材料セクション

    private var ingredientSection: some View {
        SectionCard(label: "材料") {
            VStack(spacing: 0) {
                ForEach(Array(dish.sortedIngredients.enumerated()), id: \.element.id) { index, ing in
                    HStack {
                        Text(ing.name)
                            .font(.system(size: 14))
                        Spacer()
                        Text(ing.amount)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 9)
                    if index < dish.sortedIngredients.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: - 作り方セクション

    private var stepSection: some View {
        SectionCard(label: "作り方") {
            VStack(spacing: 10) {
                ForEach(Array(dish.sortedSteps.enumerated()), id: \.element.id) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        // ステップ番号バッジ
                        ZStack {
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 24, height: 24)
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(.systemBackground))
                        }
                        .padding(.top, 2)

                        // 説明文
                        Text(step.text)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // 工程写真（横並び）
                        if let data = step.photoData,
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - リンクセクション

    private var linkSection: some View {
        SectionCard(label: "レシピ動画・リンク") {
            VStack(spacing: 8) {
                ForEach(dish.links) { link in
                    // 閲覧専用：削除ボタンなし
                    LinkCardReadOnly(link: link)
                }
            }
        }
    }

    // MARK: - メモセクション

    private var memoSection: some View {
        SectionCard(label: "メモ") {
            Text(dish.memo)
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(4)
        }
    }
}

// MARK: - LinkCardReadOnly（削除ボタンなしの閲覧専用）

struct LinkCardReadOnly: View {
    let link: RecipeLink

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconBgColor)
                    .frame(width: 36, height: 36)
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(link.title.isEmpty ? link.url : link.title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text(serviceName)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let url = URL(string: link.url) {
                Link(destination: url) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var iconName: String {
        switch link.serviceType {
        case "youtube":   return "play.fill"
        case "instagram": return "camera.fill"
        case "cookpad":   return "fork.knife"
        default:          return "link"
        }
    }

    private var iconBgColor: Color {
        switch link.serviceType {
        case "youtube":   return .red
        case "instagram": return .purple
        case "cookpad":   return .orange
        default:          return .blue
        }
    }

    private var serviceName: String {
        switch link.serviceType {
        case "youtube":   return "YouTube"
        case "instagram": return "Instagram"
        case "cookpad":   return "クックパッド"
        default:          return "リンク"
        }
    }
}
