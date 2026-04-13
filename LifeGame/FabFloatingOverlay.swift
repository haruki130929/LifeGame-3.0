import SwiftUI

/// FAB 按鈕獨立視圖 — 用 ZStack 疊在內容上面，不用 overlay modifier
/// 這樣 FAB 狀態變化不會觸發下層內容重繪
struct FabFloatingLayer: View {
    @EnvironmentObject private var fab: FabStore

    var body: some View {
        if !fab.isHidden {
            GeometryReader { proxy in
                let safeBottom = proxy.safeAreaInsets.bottom
                let safeTrailing = proxy.safeAreaInsets.trailing

                FabButton()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, safeTrailing + LayoutTokens.fabSideGap)
                    .padding(.bottom, safeBottom + LayoutTokens.fabBottomGap)
            }
            .ignoresSafeArea()
            .transition(.opacity)
        }
    }
}

/// 舊的 modifier 保留相容性，但改用 ZStack 實作
struct FabFloatingOverlay: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            content
            FabFloatingLayer()
        }
    }
}

extension View {
    func fabFloatingOverlay() -> some View {
        modifier(FabFloatingOverlay())
    }
}
