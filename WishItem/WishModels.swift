import Foundation

enum WishStatus: Int, CaseIterable, Codable {
    case active = 0
    case purchased = 1
    case dropped = 2
}

struct WishItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var price: Int?
    let createdAt: Date
    var coolDownDays: Int
    var status: WishStatus
    
    init(
        id: UUID = UUID(),
        title: String,
        price: Int? = nil,
        createdAt: Date = Date(),
        coolDownDays: Int = 7,
        status: WishStatus = .active
    ) {
        self.id = id
        self.title = title
        self.price = price
        self.createdAt = createdAt
        self.coolDownDays = coolDownDays
        self.status = status
    }
}
