import SwiftUI

/// 全 app 浮動層：把水族箱面板釘在左下角（FAB 在右下角，互不重疊）。
/// 仿 FabFloatingLayer —— 用 ZStack 疊加、GeometryReader 取安全區，空白處不攔截觸控。
struct AquariumFloatingLayer: View {
    var body: some View {
        GeometryReader { proxy in
            AquariumPanelView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, proxy.safeAreaInsets.leading + 16)
                .padding(.bottom, proxy.safeAreaInsets.bottom + 16)
        }
        .ignoresSafeArea()
    }
}

struct AquariumFloatingOverlay: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            content
            AquariumFloatingLayer()
        }
    }
}

extension View {
    func aquariumFloatingOverlay() -> some View {
        modifier(AquariumFloatingOverlay())
    }
}
