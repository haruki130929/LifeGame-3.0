import SwiftUI

struct FabFloatingOverlay: ViewModifier {
    @EnvironmentObject private var fab: FabStore

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                if !fab.isHidden {
                    GeometryReader { proxy in
                        let safeBottom = proxy.safeAreaInsets.bottom
                        let safeTrailing = proxy.safeAreaInsets.trailing

                        FabButton()
                            .padding(.trailing, safeTrailing + LayoutTokens.fabSideGap)
                            .padding(.bottom, safeBottom + LayoutTokens.fabBottomGap)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .allowsHitTesting(true)
                    }
                    .ignoresSafeArea()
                    .transition(.opacity)
                }
            }
    }
}

extension View {
    func fabFloatingOverlay() -> some View {
        modifier(FabFloatingOverlay())
    }
}
