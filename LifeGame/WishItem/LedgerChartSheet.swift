import SwiftUI

/// 記帳圖表摘要頁面
struct LedgerChartSheet: View {
    @ObservedObject var store: LedgerStore
    @Environment(\.dismiss) private var dismiss

    private var balance: Int { store.totalIncome - store.totalExpense }

    var body: some View {
        NavigationStack {
            List {
                Section("總覽") {
                    summaryRow(label: String(localized: "收入"), amount: store.totalIncome, color: .green)
                    summaryRow(label: String(localized: "支出"), amount: store.totalExpense, color: .red)
                    summaryRow(label: String(localized: "收支"), amount: balance, color: balance >= 0 ? .green : .red)
                }

                if !expenseByTitle.isEmpty {
                    Section("支出分類") {
                        ForEach(expenseByTitle, id: \.title) { item in
                            HStack {
                                Text(item.title)
                                Spacer()
                                Text("$\(item.total)")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !incomeByTitle.isEmpty {
                    Section("收入分類") {
                        ForEach(incomeByTitle, id: \.title) { item in
                            HStack {
                                Text(item.title)
                                Spacer()
                                Text("$\(item.total)")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("收支圖表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func summaryRow(label: String, amount: Int, color: Color) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("$\(amount)")
                .monospacedDigit()
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }

    // MARK: - 按標題分組

    private struct GroupedItem {
        let title: String
        let total: Int
    }

    private var expenseByTitle: [GroupedItem] {
        grouped(kind: .expense)
    }

    private var incomeByTitle: [GroupedItem] {
        grouped(kind: .income)
    }

    private func grouped(kind: LedgerEntry.Kind) -> [GroupedItem] {
        let filtered = store.entries.filter { $0.kind == kind }
        var dict: [String: Int] = [:]
        for e in filtered {
            dict[e.title, default: 0] += e.amount
        }
        return dict
            .map { GroupedItem(title: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }
}
