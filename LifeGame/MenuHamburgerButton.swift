import SwiftUI

/// 左上角選單鈕（自訂動畫版）：
/// 點擊 → 稍微縮小 → 面板開始滑出 → 面板跑到中途時，三條橫槓由上到下依序往右離開按鈕。
/// 橫槓離開後整顆鈕淡出，避免空圓圈疊在抽屜上；抽屜關閉時自動復原。
struct MenuHamburgerButton: View {
    var size: CGFloat = 52
    var showBadge: Bool = false
    /// 目前抽屜是否開啟（關閉時用來復原橫槓）
    let isDrawerOpen: Bool
    /// 點擊時呼叫（負責真正開抽屜）
    let onTap: () -> Void

    @EnvironmentObject private var theme: ThemeStore

    @State private var pressScale: CGFloat = 1.0
    @State private var barOffsetX: [CGFloat] = [0, 0, 0]
    @State private var contentOpacity: Double = 1

    private var bg: AnyShapeStyle { theme.floatingButtonFill }
    private var strokeColor: Color { theme.isDark ? .white.opacity(0.10) : .black.opacity(0.08) }
    private var fg: Color { theme.isDark ? .white.opacity(0.95) : Color(.label) }

    private let barW: CGFloat = 22
    private let barH: CGFloat = 2.6
    private let barGap: CGFloat = 5

    var body: some View {
        Button(action: triggerOpen) {
            VStack(spacing: barGap) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(fg)
                        .frame(width: barW, height: barH)
                        .offset(x: barOffsetX[i])
                }
            }
            .frame(width: size, height: size)
            .background(bg)
            .clipShape(Circle())                       // 橫槓往右飛出時會被圓形裁掉
            .overlay(Circle().stroke(strokeColor, lineWidth: 1))
            .overlay(alignment: .topTrailing) {
                if showBadge {
                    Circle().fill(.red).frame(width: 9, height: 9).offset(x: -4, y: 4)
                }
            }
            .shadow(color: .black.opacity(theme.isDark ? 0.25 : 0.12), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .scaleEffect(pressScale)
        .opacity(contentOpacity)
        .onChange(of: isDrawerOpen) { _, open in
            if !open { reset() }
        }
    }

    private func triggerOpen() {
        // 1. 點下去：面板立刻開始滑出（在橫槓後面跟著跑）
        onTap()
        withAnimation(.easeOut(duration: 0.1)) { pressScale = 0.95 }
        // 2. 面板約跑到按鈕 1/3 時，最上條先往右；後一條在前一條跑到一半就接著跑
        //    （stagger < flyDuration ⇒ 彼此重疊 → 三條排成斜的）
        let flyDuration = 0.3
        let stagger = 0.13
        let startDelay = 0.05            // ≈ 面板跑到按鈕 1/3
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + Double(i) * stagger) {
                withAnimation(.easeIn(duration: flyDuration)) {
                    barOffsetX[i] = size + barW          // 往右飛出按鈕外（被圓形裁掉）
                }
            }
        }
        // 3. 橫槓都飛走後整顆鈕淡出（面板已跟上）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.58) {
            withAnimation(.easeOut(duration: 0.2)) {
                contentOpacity = 0
                pressScale = 1.0
            }
        }
    }

    private func reset() {
        // 抽屜關閉、按鈕重新露出時復原（淡入 + 橫槓歸位）
        barOffsetX = [0, 0, 0]
        pressScale = 1.0
        withAnimation(.easeIn(duration: 0.25)) { contentOpacity = 1 }
    }
}
