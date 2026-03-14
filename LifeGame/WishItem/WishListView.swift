import SwiftUI

struct WishListView: View {
    @ObservedObject var store: WishStore
    @ObservedObject var ledgerStore: LedgerStore
    
    var body: some View {
        if store.items.isEmpty {
            ContentUnavailableView {
                Label("尚無慾望清單", systemImage: "sparkles")
            } description: {
                Text("點擊右下角「＋」按鈕，選擇「新增慾望」來加入你想買的東西吧！")
            }
        } else {
            List {
                ForEach(store.items) { item in
                    WishItemRow(item: item) { item in
                        guard let amount = item.price else { return }

                        if store.markPurchased(id: item.id) {
                            ledgerStore.addExpense(
                                title: item.title,
                                amount: amount,
                                note: "來自慾望清單",
                                wishID: item.id
                            )
                        }
                    }
                }
                .onDelete { offsets in
                    store.remove(at: offsets)
                }
                .onMove { from, to in
                    store.items.move(fromOffsets: from, toOffset: to)
                }
            }
        }
    }
}

struct WishItemRow: View {
    let item: WishItem
    let onPurchase: (WishItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.headline)
            
            if item.status == .purchased {
                Text("已購買")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Button("買了") {
                    onPurchase(item)
                }
                .buttonStyle(.borderedProminent)
                .disabled(item.price == nil)
            }
            
            if let price = item.price {
                Text("預算：\(price)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("未設定預算")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
