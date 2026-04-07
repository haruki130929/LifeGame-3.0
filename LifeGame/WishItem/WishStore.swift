import Foundation
import Combine
import SwiftUI

@MainActor
final class WishStore: ObservableObject {
    private static let storageKey = "wish_items_v1"
    private var syncHelper: StoreSyncHelper?
    private var isReloading = false

    @Published var items: [WishItem] = [] {
        didSet { if !isReloading { save() } }
    }

    init() {
        load()
        // 不再塞預設資料，讓使用者自行新增
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    func reloadFromStorage() {
        isReloading = true
        defer { isReloading = false }
        if let loaded: [WishItem] = StorageManager.load([WishItem].self, forKey: Self.storageKey) {
            items = loaded
        }
    }
    
    func add(_ item: WishItem) {
        items.insert(item, at: 0)
    }

    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
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
