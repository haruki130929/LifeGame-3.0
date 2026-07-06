import SwiftUI

/// FAB 按鈕獨立視圖 — 用 ZStack 疊在內容上面，不用 overlay modifier
/// 這樣 FAB 狀態變化不會觸發下層內容重繪
struct FabFloatingLayer: View {
    @EnvironmentObject private var fab: FabStore
    /// 慣用手：左撇子時把整個 FAB 圖層鏡像到左下角（位置與展開選單一起翻轉）
    @AppStorage(FabHandedness.storageKey) private var handedness: FabHandedness = .right

    var body: some View {
        if !fab.isHidden {
            GeometryReader { proxy in
                let safeBottom = proxy.safeAreaInsets.bottom
                let safeTrailing = proxy.safeAreaInsets.trailing

                FabButton()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, safeTrailing + LayoutTokens.fabSideGap + LayoutTokens.macEdgeInset)
                    .padding(.bottom, safeBottom + LayoutTokens.fabBottomGap + LayoutTokens.macEdgeInset)
            }
            .ignoresSafeArea()
            .transition(.opacity)
            // 右撇子＝原本的 .leftToRight（右下角）；左撇子＝鏡像成 .rightToLeft（左下角）
            .environment(\.layoutDirection, handedness == .left ? .rightToLeft : .leftToRight)
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
