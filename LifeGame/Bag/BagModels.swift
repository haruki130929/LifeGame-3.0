import Foundation

// MARK: - Bag 基本模型（給舊 UI 用）

struct BagItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var isRequired: Bool = false
}

enum BagItemEditorMode {
    case add
    case edit(BagItem)
    
    var title: String {
        switch self {
        case .add: return String(localized: "新增物品")
        case .edit: return String(localized: "編輯物品")
        }
    }
}

enum IconCategory: String, CaseIterable, Identifiable {
    case medical = "醫療"
    case money = "證件金錢"
    case stationery = "文具"
    case tech = "3C"
    case daily = "生活"

    var id: String { rawValue }

    var icons: [String] {
        switch self {
        case .medical:
            return ["bandage", "pill.fill", "facemask.fill"]
        case .money:
            return ["creditcard", "wallet.bifold"]
        case .stationery:
            return ["applepencil", "eraser.fill", "pencil.and.ruler",
                    "book", "books.vertical.fill", "text.book.closed.fill", "magazine"]
        case .tech:
            return ["iphone", "ipad", "applewatch", "airpods.max", "airpods.pro",
                    "cable.connector", "macbook", "bolt.batteryblock"]
        case .daily:
            return ["key", "backpack", "umbrella", "bag.fill", "watch.analog",
                    "comb.fill", "eyeglasses", "fork.knife"]
        }
    }
}
