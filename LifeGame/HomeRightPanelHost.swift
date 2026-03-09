import SwiftUI

/// 右側工具欄：遮罩 + 面板（抽離 HomeContentView extensions）
struct HomeRightPanelHost: View {
    @Binding var isOpen: Bool
    
    @ObservedObject var game: LifeGame
    @ObservedObject var moodStore: MoodStore
    
    var body: some View {
        ZStack {
            if isOpen {
                Color.black.opacity(DrawerPanel.overlayDimOpacity)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(DrawerPanel.panelSpring) { isOpen = false } }
                
                GeometryReader { proxy in
                    let w = proxy.size.width
                    let panelW = DrawerPanel.rightPanelWidth(for: w)
                    
                    ContentPanel(isOpen: $isOpen, game: game, mood: moodStore)
                        .frame(width: panelW)
                        .transition(.move(edge: .trailing))
                        .zIndex(51)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                }
                .ignoresSafeArea()
            }
        }
    }
}
