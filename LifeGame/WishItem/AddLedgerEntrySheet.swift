import SwiftUI

/// 新增收支記錄的表單（從 FAB 觸發）
struct AddLedgerEntrySheet: View {
    @ObservedObject var store: LedgerStore
    @Environment(\.dismiss) private var dismiss

    @State private var kind: LedgerEntry.Kind = .expense
    @State private var title: String = ""
    @State private var amountText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("類型", selection: $kind) {
                        ForEach(LedgerEntry.Kind.allCases, id: \.self) { k in
                            Text(k.title).tag(k)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("項目", text: $title)
                    TextField("金額", text: $amountText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("新增收支")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("加入") { saveAndDismiss() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                  || (Int(amountText) ?? 0) <= 0)
                }
            }
        }
    }

    private func saveAndDismiss() {
        let amt = Int(amountText) ?? 0
        guard !title.isEmpty, amt > 0 else { return }
        if kind == .expense {
            store.addExpense(title: title, amount: amt)
        } else {
            store.addIncome(title: title, amount: amt)
        }
        dismiss()
    }
}
