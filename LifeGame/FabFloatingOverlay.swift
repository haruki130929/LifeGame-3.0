import SwiftUI

struct FabFloatingOverlay: ViewModifier {
    @EnvironmentObject private var fab: FabStore

    func body(content: Content) -> some View {
        content
            .overlay {
                if !fab.isHidden {
                    GeometryReader { proxy in
                        let safeBottom = proxy.safeAreaInsets.bottom
                        let safeTrailing = proxy.safeAreaInsets.trailing

                        FabButton()
                            .coachAnchor(.fabButton)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .padding(.trailing, safeTrailing + LayoutTokens.fabSideGap)
                            .padding(.bottom, safeBottom + LayoutTokens.fabBottomGap)
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
