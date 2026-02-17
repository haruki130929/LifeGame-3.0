import SwiftUI

struct LedgerView: View {
    @ObservedObject var store: LedgerStore
    
    @State private var kind: LedgerEntry.Kind = .expense
    @State private var title: String = ""
    @State private var amountText: String = ""
    
    var body: some View {
        List {
            Section("新增") {
                Picker("類型", selection: $kind) {
                    ForEach(LedgerEntry.Kind.allCases, id: \.self) { k in
                        Text(k.title).tag(k)
                    }
                }
                
                TextField("項目", text: $title)
                TextField("金額", text: $amountText)
                    .keyboardType(.numberPad)
                
                Button("加入") {
                    let amt = Int(amountText) ?? 0
                    guard !title.isEmpty, amt > 0 else { return }
                    if kind == .expense {
                        store.addExpense(title: title, amount: amt)
                    } else {
                        store.addIncome(title: title, amount: amt)
                    }
                    title = ""
                    amountText = ""
                }
                .buttonStyle(.borderedProminent)
            }
            
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
