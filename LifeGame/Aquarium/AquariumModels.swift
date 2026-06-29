import Foundation

/// 待辦水族箱的任務類型 —— 三種形狀的魚
/// 圓＝社交、方＝體力、三角＝腦力
enum FishType: String, Codable, CaseIterable, Identifiable {
    case social    // 圓形：社交
    case physical  // 方形：體力
    case mental    // 三角：腦力

    var id: String { rawValue }

    var label: String {
        switch self {
        case .social:   return "社交"
        case .physical: return "體力"
        case .mental:   return "腦力"
        }
    }

    /// FAB／選單用的 SF Symbol（線稿幾何形）
    var systemImage: String {
        switch self {
        case .social:   return "circle"
        case .physical: return "square"
        case .mental:   return "triangle"
        }
    }
}

/// 一隻魚 ＝ 一個待辦任務（持久化 + 跨裝置同步；完成即移除，魚游走）
struct AquariumTask: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var type: FishType
    var createdAt: Date = Date()
}
