import SwiftUI

struct FabMenuModifier: ViewModifier {
    @EnvironmentObject private var fab: FabStore
    let actions: [FabAction]
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                fab.isHidden = false
                fab.currentFeatures = []
                fab.pushActions(actions)
            }
            .onDisappear { fab.popActions() }
    }
}

extension View {
    func fabMenu(_ actions: [FabAction]) -> some View {
        modifier(FabMenuModifier(actions: actions))
    }
}
