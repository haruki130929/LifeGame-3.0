import SwiftUI

struct FabFloatingOverlay: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
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
            }
    }
}

extension View {
    func fabFloatingOverlay() -> some View {
        modifier(FabFloatingOverlay())
    }
}
