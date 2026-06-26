import SwiftUI

struct FloatingIconButton: View {
    let systemName: String
    var size: CGFloat = 52
    var showBadge: Bool = false
    let action: () -> Void

    @EnvironmentObject private var theme: ThemeStore
    @State private var pressScale: CGFloat = 1.0

    private var bg: AnyShapeStyle {
        theme.floatingButtonFill
    }
    private var strokeColor: Color {
        theme.isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }
    private var fg: Color {
        theme.isDark ? .white.opacity(0.95) : Color(.label)
    }

    var body: some View {
        Button {
            // 縮小再彈回的點擊回饋（縮更小 + 彈性回彈，讓動畫更明顯）
            withAnimation(.easeOut(duration: 0.08)) {
                pressScale = 0.7
            } completion: {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.3)) {
                    pressScale = 1.0
                }
            }
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(fg)
                .overlay(alignment: .topTrailing) {
                    if showBadge {
                        Circle()
                            .fill(.red)
                            .frame(width: 9, height: 9)
                            .offset(x: 3, y: -3)
                    }
                }
                .frame(width: size, height: size)
                .background(bg)
                .clipShape(Circle())
                .overlay(Circle().stroke(strokeColor, lineWidth: 1))
                .shadow(color: .black.opacity(theme.isDark ? 0.25 : 0.12), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .scaleEffect(pressScale)
    }
}
