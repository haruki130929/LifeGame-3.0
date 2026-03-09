import Foundation
import Combine
import SwiftUI

@MainActor
final class LedgerStore: ObservableObject {
    private static let storageKey = "ledger_entries_v1"
    private var isLoading = false
    
    @Published var entries: [LedgerEntry] = [] {
        didSet {
            if !isLoading { save() }
        }
    }
    
    var totalIncome: Int {
        entries
            .filter { $0.kind == .income }
            .map { $0.amount }
            .reduce(0, +)
    }
    
    var totalExpense: Int {
        entries
            .filter { $0.kind == .expense }
            .map { $0.amount }
            .reduce(0, +)
    }
    
    init() {
        load()
    }
    
    func addExpense(title: String, amount: Int, note: String? = nil, wishID: UUID? = nil) {
        let e = LedgerEntry(title: title, amount: amount, kind: .expense, note: note, wishID: wishID)
        entries.insert(e, at: 0)
    }
    
    func addIncome(title: String, amount: Int, note: String? = nil) {
        let e = LedgerEntry(title: title, amount: amount, kind: .income, note: note)
        entries.insert(e, at: 0)
    }
    
    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
    }
    
    // MARK: - Persistence (SwiftData via StorageManager)
    private func save() {
        StorageManager.save(entries, forKey: Self.storageKey)
    }
    
    private func load() {
        isLoading = true
        defer { isLoading = false }
        
        if let saved: [LedgerEntry] = StorageManager.load([LedgerEntry].self, forKey: Self.storageKey) {
            entries = saved
        }
    }
}
