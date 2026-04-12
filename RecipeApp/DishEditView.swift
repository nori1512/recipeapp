import SwiftUI
import SwiftData
import PhotosUI

struct DishEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let dish: Dish

    @State private var menuName: String = ""
    @State private var memo: String = ""
    @State private var ingredients: [(name: String, amount: String)] = []
    @State private var linkURL: String = ""
    @State private var linkTitle: String = ""

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showLinkInput = false

    @State private var showClearAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    menuNameSection
                    photoSection
                    linkSection
                    ingredientSection
                    memoSection
                    clearSection
                }
                .padding(14)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(dish.kind.rawValue + "を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save() }
                        .fontWeight(.medium)
                }
            }
            .onAppear { load() }
            .alert("内容をクリアしますか？", isPresented: $showClearAlert) {
                Button("クリア", role: .destructive) { clearDish() }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("メニュー名・材料・写真・リンク・メモがすべて削除されます。")
            }
        }
    }

    // MARK: - Sections

    private var menuNameSection: some View {
        SectionCard(label: "メニュー名") {
            TextField("例：鶏の照り焼き", text: $menuName)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var photoSection: some View {
        SectionCard(label: "写真") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 既存写真
                    ForEach(dish.photos.sorted { $0.sortIndex < $1.sortIndex }) { photo in
                        if let uiImage = UIImage(data: photo.imageData) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                Button {
                                    context.delete(photo)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white, .black.opacity(0.5))
                                }
                                .offset(x: 4, y: -4)
                            }
                        }
                    }
                    // 追加ボタン
                    PhotosPicker(selection: $selectedPhotos, matching: .images) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 22))
                                .foregroundStyle(.tertiary)
                            Text("追加")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(width: 80, height: 80)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(style: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                .foregroundStyle(Color.secondary.opacity(0.4))
                        )
                    }
                    .onChange(of: selectedPhotos) { _, items in
                        addPhotos(items)
                    }
                }
                .padding(.bottom, 2)
            }
        }
    }

    private var linkSection: some View {
        SectionCard(label: "レシピ動画・リンク") {
            VStack(spacing: 8) {
                // 既存リンクカード
                ForEach(dish.links) { link in
                    LinkCard(link: link) {
                        context.delete(link)
                    }
                }
                // URL入力欄
                HStack(spacing: 8) {
                    TextField("URLを貼り付け", text: $linkURL)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(9)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Button("追加") {
                        addLink()
                    }
                    .font(.system(size: 13))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(linkURL.isEmpty)
                }
                // タイトル入力（オプション）
                if !linkURL.isEmpty {
                    TextField("タイトルを手動入力（任意）", text: $linkTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .padding(9)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: linkURL.isEmpty)
        }
    }

    private var ingredientSection: some View {
        SectionCard(label: "材料") {
            VStack(spacing: 6) {
                ForEach(ingredients.indices, id: \.self) { i in
                    HStack(spacing: 8) {
                        TextField("食材名", text: Binding(
                            get: { ingredients[i].name },
                            set: { ingredients[i].name = $0 }
                        ))
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .padding(9)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        TextField("量", text: Binding(
                            get: { ingredients[i].amount },
                            set: { ingredients[i].amount = $0 }
                        ))
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .frame(width: 80)
                        .padding(9)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button {
                            ingredients.remove(at: i)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }

                Button {
                    ingredients.append((name: "", amount: ""))
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("材料を追加")
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(style: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.secondary.opacity(0.4))
                    )
                }
            }
        }
    }

    private var memoSection: some View {
        SectionCard(label: "メモ") {
            TextField("調理のポイントなど", text: $memo, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .lineLimit(3...8)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var clearSection: some View {
        Button {
            showClearAlert = true
        } label: {
            Text("内容をクリア")
                .font(.system(size: 15))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red.opacity(0.3), lineWidth: 0.5)
                )
        }
    }

    // MARK: - Load / Save

    private func load() {
        menuName = dish.menuName
        memo = dish.memo
        ingredients = dish.sortedIngredients.map { (name: $0.name, amount: $0.amount) }
        if ingredients.isEmpty { ingredients = [("", "")] }
    }

    private func save() {
        dish.menuName = menuName
        dish.memo = memo

        // Ingredients: 既存を削除して再作成
        dish.ingredients.forEach { context.delete($0) }
        let filtered = ingredients.filter { !$0.name.isEmpty }
        for (i, item) in filtered.enumerated() {
            let ing = Ingredient(name: item.name, amount: item.amount, sortIndex: i)
            ing.dish = dish
            context.insert(ing)
        }

        try? context.save()
        dismiss()
    }

    private func clearDish() {
        dish.menuName = ""
        dish.memo = ""
        dish.ingredients.forEach { context.delete($0) }
        dish.photos.forEach { context.delete($0) }
        dish.links.forEach { context.delete($0) }
        try? context.save()
        dismiss()
    }

    private func addLink() {
        guard !linkURL.isEmpty, URL(string: linkURL) != nil else { return }
        let serviceType = RecipeLink.detect(from: linkURL)
        let title = linkTitle.isEmpty ? linkURL : linkTitle
        let link = RecipeLink(url: linkURL, title: title, serviceType: serviceType)
        link.dish = dish
        context.insert(link)
        try? context.save()
        linkURL = ""
        linkTitle = ""
    }

    private func addPhotos(_ items: [PhotosPickerItem]) {
        let startIndex = dish.photos.count
        for (offset, item) in items.enumerated() {
            item.loadTransferable(type: Data.self) { result in
                if case .success(let data) = result, let data {
                    DispatchQueue.main.async {
                        let photo = RecipePhoto(imageData: data, sortIndex: startIndex + offset)
                        photo.dish = dish
                        context.insert(photo)
                        try? context.save()
                    }
                }
            }
        }
        selectedPhotos = []
    }
}

// MARK: - SectionCard

struct SectionCard<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            content
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}

// MARK: - LinkCard

struct LinkCard: View {
    let link: RecipeLink
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // サービスアイコン
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

            // 開くボタン
            if let url = URL(string: link.url) {
                Link(destination: url) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(.tertiaryLabel), Color(.quaternarySystemFill))
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
        case "youtube":   return Color.red
        case "instagram": return Color.purple
        case "cookpad":   return Color.orange
        default:          return Color.blue
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
