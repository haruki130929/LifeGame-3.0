import Foundation
import Combine

@MainActor
final class WishStore: ObservableObject {
    private static let storageKey = "wish_items_v1"
    
    @Published var items: [WishItem] = [] {
        didSet { save() }
    }
    
    init() {
        load()
        if items.isEmpty {
            // 第一次使用才塞預設資料
            items = [
                WishItem(title: "Sony 耳機", price: 12000),
                WishItem(title: "新鍵盤", price: 3500),
                WishItem(title: "筆電支架")
            ]
        }
    }
    
    func markPurchased(id: UUID) -> Bool {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return false }
        guard items[idx].status != .purchased else { return false } // 一次性
        items[idx].status = .purchased
        return true
    }
    
    private func save() {
        StorageManager.save(items, forKey: Self.storageKey)
    }
    
    private func load() {
        if let loaded: [WishItem] = StorageManager.load([WishItem].self, forKey: Self.storageKey) {
            items = loaded
        }
    }
}
