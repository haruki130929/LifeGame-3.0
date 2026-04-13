import SwiftUI

struct FabMenuModifier: ViewModifier {
    @EnvironmentObject private var fab: FabStore
    let actions: [FabAction]
    @State private var didSetup = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !didSetup else { return }
                didSetup = true
                fab.isHidden = false
                fab.currentFeatures = []
                fab.pushActions(actions)
            }
            .onDisappear {
                didSetup = false
                fab.popActions()
            }
    }
}

extension View {
    func fabMenu(_ actions: [FabAction]) -> some View {
        modifier(FabMenuModifier(actions: actions))
    }
}
