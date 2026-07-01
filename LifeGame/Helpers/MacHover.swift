import SwiftUI

// Mac Catalyst 專用的滑鼠 hover 回饋。
// iPhone / iPad 上是 no-op（回傳 self），對觸控行為零影響。

#if targetEnvironment(macCatalyst)

extension View {
    /// 滑鼠移到可點元件上時，輕微提亮 + 微幅放大，讓 Mac 使用者知道它可以點。
    func macHoverHighlight() -> some View {
        modifier(MacHoverHighlight())
    }
}

private struct MacHoverHighlight: ViewModifier {
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .brightness(hovering ? 0.05 : 0)
            .scaleEffect(hovering ? 1.012 : 1.0)
            .animation(.easeOut(duration: 0.14), value: hovering)
            .onHover { hovering = $0 }
    }
}

#else

extension View {
    /// 非 Catalyst：no-op。
    @inline(__always)
    func macHoverHighlight() -> some View { self }
}

#endif
