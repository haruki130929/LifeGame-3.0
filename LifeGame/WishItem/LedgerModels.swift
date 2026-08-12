import Foundation

struct LedgerEntry: Identifiable, Codable {
    enum Kind: Int, CaseIterable, Codable {
        case expense = 0
        case income = 1
        
        var title: String { self == .expense ? String(localized: "支出") : String(localized: "收入") }
    }
    
    let id: UUID
    var title: String
    var amount: Int
    var kind: Kind
    var createdAt: Date
    var note: String?
    var wishID: UUID?
    
    init(
        id: UUID = UUID(),
        title: String,
        amount: Int,
        kind: Kind,
        createdAt: Date = Date(),
        note: String? = nil,
        wishID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.kind = kind
        self.createdAt = createdAt
        self.note = note
        self.wishID = wishID
    }
}
