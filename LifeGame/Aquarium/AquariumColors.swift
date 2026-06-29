import SwiftUI

/// 水族箱配色（先用原型的藍／橘／綠，深色模式有對應較亮的版本）。
/// 之後若要換成 app 的和風色盤，只改這裡即可。
enum AquariumPalette {

    /// 魚身的實心色塊顏色
    static func bodyColor(for type: FishType, isDark: Bool) -> Color {
        switch type {
        case .social:   return Color(hex: isDark ? "5AA0E8" : "378ADD") ?? .blue
        case .physical: return Color(hex: isDark ? "E8794F" : "D85A30") ?? .orange
        case .mental:   return Color(hex: isDark ? "35B589" : "1D9E75") ?? .green
        }
    }

    /// 水箱背景水色
    static func waterColor(isDark: Bool) -> Color {
        (isDark ? Color(hex: "11313F") : Color(hex: "E6F1FB"))
            ?? (isDark ? Color.blue.opacity(0.18) : Color.blue.opacity(0.08))
    }
}
