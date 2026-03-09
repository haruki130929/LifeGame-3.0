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
        case .add: return "新增物品"
        case .edit: return "編輯物品"
        }
    }
}

enum IconCategory: String, CaseIterable, Identifiable {
    case stationery = "文具"
    case tech = "3C"
    case daily = "生活"
    case medical = "醫療"
    case rain = "雨具"
    case money = "證件金錢"
    case other = "其他"
    
    var id: String { rawValue }
    
    var icons: [String] {
        switch self {
        case .stationery:
            return ["pencil","pencil.and.outline","pencil.tip","book","books.vertical","notebook",
                    "doc.text","folder","paperclip","scissors","highlighter","bookmark"]
        case .tech:
            return ["headphones","earbuds","phone","iphone","cable.connector",
                    "battery.100.bolt","bolt","powerplug","wifi","flashlight.on.fill"]
        case .daily:
            return ["backpack","bag","waterbottle","cup.and.saucer","eyeglasses",
                    "clock","watch.analog","tshirt","hanger"]
        case .medical:
            return ["bandage","cross.case","pills","heart.text.square","stethoscope"]
        case .rain:
            return ["umbrella","cloud.rain","drop"]
        case .money:
            return ["wallet.pass","creditcard","idcard","person.text.rectangle"]
        case .other:
            return ["key","airtag","carabiner","star","sparkles"]
        }
    }
}
