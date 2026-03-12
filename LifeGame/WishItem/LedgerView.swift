import SwiftUI

struct LedgerView: View {
    @ObservedObject var store: LedgerStore

    var body: some View {
        List {
            Section("總計") {
                HStack {
                    Text("收入")
                    Spacer()
                    Text(store.totalIncome.formatted())
                }
                HStack {
                    Text("支出")
                    Spacer()
                    Text(store.totalExpense.formatted())
                }
                HStack {
                    Text("收支")
                    Spacer()
                    Text((store.totalIncome - store.totalExpense).formatted())
                }
            }
            
            Section("紀錄") {
                ForEach(store.entries) { e in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(e.title).font(.headline)
                            Text(e.kind == .expense ? "支出" : "收入")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            if e.wishID != nil {
                                Text("來自慾望清單")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(e.amount.formatted())
                    }
                }
                .onDelete { offsets in
                    store.delete(at: offsets)
                }
            }
        }
    }
}
