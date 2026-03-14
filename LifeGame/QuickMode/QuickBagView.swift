import SwiftUI
import SwiftData

/// Quick Mode 專用：收拾書包（不含底部重設/打勾按鈕）
struct QuickBagView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BagItemModel.name) private var items: [BagItemModel]

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 100), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(items) { item in
                    BagItemCard(item: item) {
                        toggle(item)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .onAppear { seedIfNeeded() }
    }

    // MARK: - Actions

    private func toggle(_ item: BagItemModel) {
        item.isChecked.toggle()
        try? context.save()
    }

    private func seedIfNeeded() {
        guard items.isEmpty else { return }
        let defaults: [(String, String, Bool)] = [
            ("錢包", "wallet.pass", true),
            ("鑰匙", "key", true),
            ("耳機", "headphones", true),
            ("充電線", "cable.connector", false),
            ("行動電源", "battery.100.bolt", false),
            ("水壺", "waterbottle", true),
            ("筆袋", "pencil", true),
            ("手帳本", "book", false),
            ("課本／講義", "books.vertical", false)
        ]
        for (name, icon, req) in defaults {
            context.insert(BagItemModel(name: name, icon: icon, isRequired: req, isChecked: false))
        }
        try? context.save()
    }
}
