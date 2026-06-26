import SwiftUI

struct DashboardCardShell<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.headline)

                Spacer()
            }

            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

// MARK: - Card Surface（卡片底樣式：實心／毛玻璃／iOS 26 玻璃，三個卡片 shell 共用）

private struct CardSurfaceModifier: ViewModifier {
    @EnvironmentObject private var theme: ThemeStore
    var cornerRadius: CGFloat = 18

    private var shadowColor: Color { theme.isDark ? .black.opacity(0.3) : .black.opacity(0.08) }
    private var shadowRadius: CGFloat { theme.isDark ? 10 : 8 }
    private var shadowY: CGFloat { theme.isDark ? 6 : 3 }
    private var strokeColor: Color { theme.isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.10) }

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        switch theme.cardSurfaceStyle {
        case .glass:
            filled(content, shape: shape, style: AnyShapeStyle(.thinMaterial))
        case .solid:
            filled(content, shape: shape, style: AnyShapeStyle(theme.isDark ? Color(white: 0.18) : Color.white))
        }
    }

    private func filled(_ content: Content, shape: RoundedRectangle, style: AnyShapeStyle) -> some View {
        content
            .background { shape.fill(style) }
            .clipShape(shape)
            .overlay(shape.strokeBorder(strokeColor, lineWidth: 1))
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }
}

extension View {
    /// 卡片統一底樣式，依 `ThemeStore.cardSurfaceStyle` 切換實心／毛玻璃／玻璃。
    func cardSurface(cornerRadius: CGFloat = 18) -> some View {
        modifier(CardSurfaceModifier(cornerRadius: cornerRadius))
    }
}
