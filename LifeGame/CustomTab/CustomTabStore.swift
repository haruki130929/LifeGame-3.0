import Foundation
import Combine

// MARK: - CustomTab 資料模型

struct CustomTab: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var icon: String           // SF Symbol 名稱
    var cardTypes: [CardType]  // 該切頁要顯示的卡片（有序）

    init(id: UUID = UUID(), name: String, icon: String = "square.grid.2x2", cardTypes: [CardType]) {
        self.id = id
        self.name = name
        self.icon = icon
        self.cardTypes = cardTypes
    }
}

// MARK: - CustomTabStore

final class CustomTabStore: ObservableObject {
    @Published private(set) var tabs: [CustomTab] {
        didSet { save() }
    }

    private let key = "custom_tabs_v1"

    init() {
        if var saved: [CustomTab] = StorageManager.load([CustomTab].self, forKey: key) {
            // 遷移：確保第一個切頁包含 tomorrowRing
            if !saved.isEmpty {
                let first = saved[0]
                if !first.cardTypes.contains(.tomorrowRing) {
                    var updated = first
                    // 插在最前面
                    updated.cardTypes.insert(.tomorrowRing, at: 0)
                    saved[0] = updated
                }
            }
            self.tabs = saved
        } else {
            // 初次安裝：預設一個「工具」切頁
            self.tabs = [
                CustomTab(
                    name: "工具",
                    icon: "wrench.and.screwdriver.fill",
                    cardTypes: [.tomorrowRing, .calendar, .todoQuadrant]
                )
            ]
        }
    }

    // MARK: - CRUD

    func add(_ tab: CustomTab) {
        tabs.append(tab)
    }

    func update(_ tab: CustomTab) {
        if let i = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs[i] = tab
        }
    }

    func remove(id: UUID) {
        tabs.removeAll { $0.id == id }
    }

    // MARK: - Persistence

    private func save() {
        StorageManager.save(tabs, forKey: key)
    }
}
