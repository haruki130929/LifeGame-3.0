import SwiftUI
import Combine

struct FabAction: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let action: () -> Void
}

@MainActor
final class FabStore: ObservableObject {
    enum Route: Identifiable, Equatable {  // ✅ 加上 Equatable
        case addCalendarEvent
        case navigate(FeatureID)
        
        var id: String {
            switch self {
            case .addCalendarEvent:    return "addCalendarEvent"
            case .navigate(let f):     return "navigate-\(f)"
            }
        }
    }
    
    @Published var isExpanded: Bool = false
    @Published private(set) var actions: [FabAction] = []
    @Published private(set) var subActions: [FabAction] = []
    @Published var showSubMenu: Bool = false
    @Published var selectedFeature: FeatureID? = nil
    @Published var route: Route? = nil
    
    private var featureStack: [[FabAction]] = []
    
    func setRootActions(_ actions: [FabAction]) {
        featureStack = [actions]
        self.actions = actions
        hideSubMenu()
        collapse()
    }
    
    func pushActions(_ actions: [FabAction]) {
        featureStack.append(actions)
        self.actions = actions
        hideSubMenu()
        collapse()
    }
    
    func popActions() {
        guard featureStack.count > 1 else { return }
        featureStack.removeLast()
        self.actions = featureStack.last ?? []
        hideSubMenu()
        collapse()
    }
    
    func collapse() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            isExpanded = false
        }
        hideSubMenu()
    }
    
    func toggle() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            isExpanded.toggle()
        }
        if !isExpanded { hideSubMenu() }
    }
    
    func selectFeature(_ feature: FeatureID) {
        selectedFeature = feature
        subActions = makeSubActions(for: feature)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            showSubMenu = true
        }
    }
    
    func hideSubMenu() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
            showSubMenu = false
            selectedFeature = nil
        }
    }
    
    func apply(context: FabContext) {
        switch context {
        case let .home(_, features):
            setRootActions(makeHomeActions(features: features))
        case let .feature(feature):
            pushActions(makeDetailActions(for: feature))
        }
    }
    
    private func makeHomeActions(features: [FeatureID]) -> [FabAction] {
        features.map { feature in
            FabAction(
                title: title(for: feature),
                systemImage: icon(for: feature)
            ) { [weak self] in
                guard let self else { return }
                if self.selectedFeature == feature {
                    self.hideSubMenu()
                } else {
                    self.selectFeature(feature)
                }
            }
        }
    }
    
    private func makeSubActions(for feature: FeatureID) -> [FabAction] {
        var result: [FabAction] = [
            FabAction(title: "返回", systemImage: "chevron.backward") { [weak self] in
                self?.hideSubMenu()
            }
        ]
        
        switch feature {
        case .calendar:
            result += [
                FabAction(title: "行事曆", systemImage: "calendar") { [weak self] in
                    self?.route = .navigate(.calendar); self?.collapse()
                },
                FabAction(title: "新增行程", systemImage: "calendar.badge.plus") { [weak self] in
                    self?.route = .addCalendarEvent; self?.collapse()
                },
                FabAction(title: "今天", systemImage: "sun.max") { [weak self] in
                    self?.route = .navigate(.calendar); self?.collapse()
                },
                FabAction(title: "切換月/週", systemImage: "arrow.left.arrow.right") { [weak self] in
                    self?.route = .navigate(.calendar); self?.collapse()
                }
            ]
        case .diary:
            result += [
                FabAction(title: "日記", systemImage: "book") { [weak self] in
                    self?.route = .navigate(.diary); self?.collapse()
                },
                FabAction(title: "新增日記", systemImage: "square.and.pencil") { [weak self] in
                    self?.route = .navigate(.diary); self?.collapse()
                },
                FabAction(title: "搜尋日記", systemImage: "magnifyingglass") { [weak self] in
                    self?.route = .navigate(.diary); self?.collapse()
                }
            ]
        case .ledger:
            result += [
                FabAction(title: "記帳", systemImage: "creditcard") { [weak self] in
                    self?.route = .navigate(.ledger); self?.collapse()
                },
                FabAction(title: "新增支出", systemImage: "minus.circle") { [weak self] in
                    self?.route = .navigate(.ledger); self?.collapse()
                },
                FabAction(title: "新增收入", systemImage: "plus.circle") { [weak self] in
                    self?.route = .navigate(.ledger); self?.collapse()
                }
            ]
        case .wish:
            result += [
                FabAction(title: "願望清單", systemImage: "sparkles") { [weak self] in
                    self?.route = .navigate(.wish); self?.collapse()
                },
                FabAction(title: "新增願望", systemImage: "plus") { [weak self] in
                    self?.route = .navigate(.wish); self?.collapse()
                }
            ]
        case .settings:
            result += [
                FabAction(title: "設定", systemImage: "gearshape") { [weak self] in
                    self?.route = .navigate(.settings); self?.collapse()
                }
            ]
        }
        
        return result
    }
    
    private func makeDetailActions(for feature: FeatureID) -> [FabAction] {
        var result: [FabAction] = [
            FabAction(title: "返回", systemImage: "chevron.backward") { [weak self] in
                self?.popActions()
            }
        ]
        
        switch feature {
        case .calendar:
            result += [
                FabAction(title: "新增行程", systemImage: "calendar.badge.plus") { [weak self] in
                    self?.route = .addCalendarEvent; self?.collapse()
                },
                FabAction(title: "今天", systemImage: "sun.max") { print("TODO: 回到今天") },
                FabAction(title: "切換月/週", systemImage: "arrow.left.arrow.right") { print("TODO: 切換月週") }
            ]
        case .diary:
            result += [
                FabAction(title: "新增日記", systemImage: "square.and.pencil") { print("TODO: 新增日記") },
                FabAction(title: "搜尋日記", systemImage: "magnifyingglass") { print("TODO: 搜尋日記") }
            ]
        case .ledger:
            result += [
                FabAction(title: "新增支出", systemImage: "minus.circle") { print("TODO: 新增支出") },
                FabAction(title: "新增收入", systemImage: "plus.circle") { print("TODO: 新增收入") }
            ]
        case .wish:
            result += [
                FabAction(title: "新增願望", systemImage: "sparkles") { print("TODO: 新增願望") }
            ]
        case .settings:
            result += [
                FabAction(title: "偏好設定", systemImage: "gearshape") { print("TODO: 偏好設定") }
            ]
        }
        
        return result
    }
    
    private func title(for feature: FeatureID) -> String {
        switch feature {
        case .calendar: return "行事曆"
        case .diary:    return "日記"
        case .wish:     return "願望"
        case .ledger:   return "記帳"
        case .settings: return "設定"
        }
    }
    
    private func icon(for feature: FeatureID) -> String {
        switch feature {
        case .calendar: return "calendar"
        case .diary:    return "book"
        case .wish:     return "sparkles"
        case .ledger:   return "creditcard"
        case .settings: return "gearshape"
        }
    }
}
