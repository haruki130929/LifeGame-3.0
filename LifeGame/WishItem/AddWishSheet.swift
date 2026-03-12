import SwiftUI

/// 新增慾望的表單（從 FAB 觸發）
struct AddWishSheet: View {
    @ObservedObject var store: WishStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var priceText: String = ""
    @State private var coolDownDays: Int = 7

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("慾望名稱", text: $title)
                    TextField("預算（選填）", text: $priceText)
                        .keyboardType(.numberPad)
                }

                Section("冷靜期") {
                    Stepper("\(coolDownDays) 天", value: $coolDownDays, in: 0...90)
                }
            }
            .navigationTitle("新增慾望")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("加入") { saveAndDismiss() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveAndDismiss() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let price = Int(priceText)
        let item = WishItem(title: trimmed, price: price, coolDownDays: coolDownDays)
        store.add(item)
        dismiss()
    }
}
