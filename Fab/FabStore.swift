import SwiftUI

struct FabAction: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let action: () -> Void
}

final class FabStore: ObservableObject {
    @Published var isExpanded: Bool = false
    @Published private(set) var actions: [FabAction] = []
    
    private var stack: [[FabAction]] = []
    
    // 舊 API：如果你專案其他地方還在用 setActions，不會炸
    func setActions(_ actions: [FabAction]) {
        setRootActions(actions)
    }
    
    // 主頁用（root）
    func setRootActions(_ actions: [FabAction]) {
        stack = [actions]
        self.actions = actions
        isExpanded = false
    }
    
    // 功能頁用（之後要做「進功能頁換選單」就用這個）
    func pushActions(_ actions: [FabAction]) {
        stack.append(actions)
        self.actions = actions
        isExpanded = false
    }
    
    func popActions() {
        guard stack.count > 1 else { return }
        stack.removeLast()
        self.actions = stack.last ?? []
        isExpanded = false
    }
}
