import SwiftUI
import SwiftData

/// Quick Mode 專用：整理書包（不含底部重設/打勾按鈕）
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
        context.safeSave()
    }

    private func seedIfNeeded() {
        BagSeeder.seedIfNeeded(context: context)
    }
}
