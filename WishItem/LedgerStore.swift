import Foundation

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
    
    // MARK: - Persistence
    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            print("LedgerStore save failed:", error)
        }
    }
    
    private func load() {
        isLoading = true
        defer { isLoading = false }
        
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return }
        do {
            entries = try JSONDecoder().decode([LedgerEntry].self, from: data)
        } catch {
            print("LedgerStore load failed:", error)
        }
    }
}
