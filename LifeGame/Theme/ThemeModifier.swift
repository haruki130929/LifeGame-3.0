// ThemeModifier.swift
import SwiftUI

private struct ThemeApplier: ViewModifier {
    @EnvironmentObject private var theme: ThemeStore

    /// 讀取「套用 .preferredColorScheme 之前」的系統色系，
    /// 當使用者選「跟隨系統」時，就直接用裝置原本的深淺模式。
    @Environment(\.colorScheme) private var systemColorScheme

    func body(content: Content) -> some View {
        // 解析最終應該用哪個 colorScheme
        let resolved: ColorScheme = theme.appearance.preferredColorScheme ?? systemColorScheme

        content
            .tint(theme.accentColor)
            // ① 告訴 Window 級別用哪個色系（影響狀態列 / 導航列等）
            .preferredColorScheme(theme.appearance.preferredColorScheme)
            // ② 直接覆寫 Environment，確保所有子視圖的 @Environment(\.colorScheme) 都拿到正確值
            .environment(\.colorScheme, resolved)
            .environment(\.dynamicTypeSize, mappedDynamicType(from: theme.fontScale))
    }

    private func mappedDynamicType(from scale: Double) -> DynamicTypeSize {
        switch scale {
        case ..<0.90: return .small
        case ..<0.98: return .medium
        case ..<1.06: return .large
        case ..<1.14: return .xLarge
        default: return .xxLarge
        }
    }
}

extension View {
    func applyTheme() -> some View {
        modifier(ThemeApplier())
    }
}
