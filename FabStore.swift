import SwiftUI

// MARK: - Action
struct FabAction: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let action: () -> Void
}

// MARK: - Store
@MainActor
final class FabStore: ObservableObject {
    @Published var isExpanded: Bool = false
    @Published var actions: [FabAction] = []
    
    func setActions(_ actions: [FabAction]) {
        self.actions = actions
    }
    
    func toggle() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            isExpanded.toggle()
        }
    }
    
    func collapse() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            isExpanded = false
        }
    }
}
