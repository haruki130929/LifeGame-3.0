// ThemeModifier.swift
import SwiftUI

private struct ThemeApplier: ViewModifier {
    @EnvironmentObject private var theme: ThemeStore
    
    func body(content: Content) -> some View {
        content
            .tint(theme.accentColor) // ✅ 按鈕/Toggle/Slider/Segmented 等控制元件
            .preferredColorScheme(theme.appearance.preferredColorScheme) // ✅ 淺/深/系統
            .environment(\.dynamicTypeSize, mappedDynamicType(from: theme.fontScale)) // ✅ 字體倍率
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
