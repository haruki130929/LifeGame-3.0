import SwiftUI

struct DashboardCardContainer<Content: View>: View {
    let content: Content
    @EnvironmentObject private var theme: ThemeStore

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if theme.isDark {
                    shape.fill(.thinMaterial)
                } else {
                    shape.fill(Color.white)
                }
            }
            .clipShape(shape)
            .overlay(
                shape.strokeBorder(
                    theme.isDark
                        ? Color.white.opacity(0.06)
                        : Color.black.opacity(0.10),
                    lineWidth: 1
                )
            )
            .shadow(
                color: theme.isDark ? .black.opacity(0.3) : .black.opacity(0.08),
                radius: theme.isDark ? 10 : 8,
                x: 0,
                y: theme.isDark ? 6 : 3
            )
    }
}
