import SwiftUI

struct FabFloatingOverlay: ViewModifier {
    @EnvironmentObject private var fab: FabStore
    @EnvironmentObject private var coachMarkStore: CoachMarkStore

    func body(content: Content) -> some View {
        content
            .overlay {
                if !fab.isHidden {
                    GeometryReader { proxy in
                        let safeBottom = proxy.safeAreaInsets.bottom
                        let safeTrailing = proxy.safeAreaInsets.trailing

                        FabButton()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .padding(.trailing, safeTrailing + LayoutTokens.fabSideGap)
                            .padding(.bottom, safeBottom + LayoutTokens.fabBottomGap)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .onAppear {
                                            DispatchQueue.main.async {
                                                let f = geo.frame(in: .global)
                                                coachMarkStore.reportCenter(
                                                    CGPoint(x: f.midX, y: f.midY),
                                                    for: .fabButton
                                                )
                                            }
                                        }
                                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                                            coachMarkStore.reportCenter(
                                                CGPoint(x: newFrame.midX, y: newFrame.midY),
                                                for: .fabButton
                                            )
                                        }
                                }
                            )
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
