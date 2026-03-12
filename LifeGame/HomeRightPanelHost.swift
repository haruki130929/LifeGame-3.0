import SwiftUI

/// 右側工具欄：遮罩 + 面板（與左側抽屜對稱的滑入式）
struct HomeRightPanelHost: View {
    @Binding var isOpen: Bool

    @ObservedObject var game: LifeGame
    @ObservedObject var moodStore: MoodStore
    var onNavigateToMood: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .trailing) {
            if isOpen {
                Color.black.opacity(DrawerPanel.overlayDimOpacity)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeInOut) { isOpen = false } }
            }

            GeometryReader { proxy in
                let w = proxy.size.width
                let panelW = DrawerPanel.rightPanelWidth(for: w)

                ContentPanel(
                    isOpen: $isOpen,
                    game: game,
                    mood: moodStore,
                    onNavigateToMood: onNavigateToMood
                )
                .frame(width: panelW)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .offset(x: isOpen ? 0 : panelW + DrawerPanel.drawerHiddenExtra)
                .animation(.easeInOut(duration: DrawerPanel.drawerAnimDuration), value: isOpen)
                .allowsHitTesting(isOpen)
                .zIndex(51)
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            if value.translation.width > 60 {
                                withAnimation(.easeInOut) { isOpen = false }
                            }
                        }
                )
            }
            .ignoresSafeArea()
        }
    }
}
