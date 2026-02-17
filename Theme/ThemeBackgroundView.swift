// ThemeBackgroundView.swift
import SwiftUI

struct ThemeBackgroundView<Content: View>: View {
    let style: ThemeStore.BackgroundStyle
    @ViewBuilder var content: () -> Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    // ✅ 版本 A：有 style（推薦用這個）
    init(style: ThemeStore.BackgroundStyle, @ViewBuilder content: @escaping () -> Content) {
        self.style = style
        self.content = content
    }
    
    // ✅ 版本 B：沒 style（為了救 “Missing argument for parameter 'style'”）
    init(@ViewBuilder content: @escaping () -> Content) {
        self.style = .system
        self.content = content
    }
    
    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            content()
        }
    }
    
    @ViewBuilder
    private var background: some View {
        switch style {
        case .system:
            Color(.systemBackground)
            
        case .gradient:
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .light:
            if colorScheme == .dark {
                Color(.secondarySystemBackground)
            } else {
                Color(.systemGray6)
            }
        }
    }
    
    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(.sRGB, red: 0.10, green: 0.10, blue: 0.12, opacity: 1.0),
                Color(.sRGB, red: 0.06, green: 0.06, blue: 0.08, opacity: 1.0)
            ]
        } else {
            return [
                Color(.sRGB, red: 0.97, green: 0.97, blue: 0.99, opacity: 1.0),
                Color(.sRGB, red: 0.92, green: 0.94, blue: 0.98, opacity: 1.0)
            ]
        }
    }
}
