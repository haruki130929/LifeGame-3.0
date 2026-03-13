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
    enum Route: Identifiable, Equatable {
        case addCalendarEvent
        case jumpToToday
        case navigate(FeatureID)
        // ── 時間圓環專用 ──
        case addRingItem
        case quickAppendRing
        // ── 待辦四象限專用 ──
        case addTodoToQuadrant(TodoQuadrant)
        case todoEditMode
        // ── 每日紀錄專用 ──
        case addDailyLog
        // ── 財務專用 ──
        case addWish
        case editWishList
        case addLedgerEntry
        case viewLedgerChart
        // ── 本月結算專用 ──
        case monthlyScoreStats
        // ── 功能設定 ──
        case featureSettings(FeatureID)

        var id: String {
            switch self {
            case .addCalendarEvent:         return "addCalendarEvent"
            case .jumpToToday:              return "jumpToToday"
            case .navigate(let f):          return "navigate-\(f)"
            case .addRingItem:              return "addRingItem"
            case .quickAppendRing:          return "quickAppendRing"
            case .addTodoToQuadrant(let q): return "addTodo-\(q.rawValue)"
            case .todoEditMode:             return "todoEditMode"
            case .addDailyLog:              return "addDailyLog"
            case .addWish:                  return "addWish"
            case .editWishList:             return "editWishList"
            case .addLedgerEntry:           return "addLedgerEntry"
            case .viewLedgerChart:          return "viewLedgerChart"
            case .monthlyScoreStats:        return "monthlyScoreStats"
            case .featureSettings(let f):   return "featureSettings-\(f)"
            }
        }
    }

    @Published var isHidden: Bool = false
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

    // MARK: - Home Actions（從 SlotCard 卡片 → FAB 選單項目）

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

    // MARK: - Sub Actions（主頁面點擊功能後展開的細部選單，不含設定）

    private func makeSubActions(for feature: FeatureID) -> [FabAction] {
        return makeCoreActions(for: feature)
    }

    // MARK: - Detail Actions（進入功能頁面後的 FAB，含設定）

    private func makeDetailActions(for feature: FeatureID) -> [FabAction] {
        var result = makeCoreActions(for: feature)

        // 功能頁最後加「設定」，跳到該功能的設定頁（設定頁本身除外）
        if feature != .settings {
            result.append(
                FabAction(title: "設定", systemImage: "gearshape") { [weak self] in
                    self?.route = .featureSettings(feature); self?.collapse()
                }
            )
        }

        return result
    }

    // MARK: - Core Actions（各功能的核心操作，不含設定）

    private func makeCoreActions(for feature: FeatureID) -> [FabAction] {
        var result: [FabAction] = []

        switch feature {
        case .calendar:
            result += [
                FabAction(title: "新增行程", systemImage: "calendar.badge.plus") { [weak self] in
                    self?.route = .addCalendarEvent; self?.collapse()
                },
                FabAction(title: "跳到今天", systemImage: "sun.max") { [weak self] in
                    self?.route = .jumpToToday; self?.collapse()
                }
            ]
        case .diary:
            result += [
                FabAction(title: "新增日記", systemImage: "square.and.pencil") { [weak self] in
                    self?.route = .navigate(.diary); self?.collapse()
                }
            ]
        case .ledger:
            result += [
                FabAction(title: "新增收支", systemImage: "plus.circle") { [weak self] in
                    self?.route = .addLedgerEntry; self?.collapse()
                },
                FabAction(title: "檢視圖表", systemImage: "chart.pie") { [weak self] in
                    self?.route = .viewLedgerChart; self?.collapse()
                }
            ]
        case .wish:
            result += [
                FabAction(title: "新增慾望", systemImage: "sparkles") { [weak self] in
                    self?.route = .addWish; self?.collapse()
                },
                FabAction(title: "編輯", systemImage: "pencil") { [weak self] in
                    self?.route = .editWishList; self?.collapse()
                }
            ]
        case .settings:
            result += [
                FabAction(title: "偏好設定", systemImage: "gearshape") { [weak self] in
                    self?.route = .navigate(.settings); self?.collapse()
                }
            ]
        case .dailyLog:
            result += [
                FabAction(title: "新增日記", systemImage: "plus.circle") { [weak self] in
                    self?.route = .addDailyLog; self?.collapse()
                }
            ]
        case .todoQuadrant:
            result += [
                FabAction(title: "新增待辦事項", systemImage: "plus.circle") { [weak self] in
                    guard let self else { return }
                    self.subActions = TodoQuadrant.allCases.map { q in
                        FabAction(title: q.title, systemImage: q.fabIcon) { [weak self] in
                            self?.route = .addTodoToQuadrant(q); self?.collapse()
                        }
                    }
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        self.showSubMenu = true
                    }
                },
                FabAction(title: "編輯", systemImage: "pencil") { [weak self] in
                    self?.route = .todoEditMode; self?.collapse()
                }
            ]
        case .tomorrowRing:
            result += [
                FabAction(title: "新增時段", systemImage: "plus.circle") { [weak self] in
                    self?.route = .addRingItem; self?.collapse()
                },
                FabAction(title: "快速接續", systemImage: "arrow.right.circle") { [weak self] in
                    self?.route = .quickAppendRing; self?.collapse()
                }
            ]
        case .bagRequired:
            result += [
                FabAction(title: "編輯清單", systemImage: "checklist") { [weak self] in
                    self?.route = .navigate(.bagRequired); self?.collapse()
                }
            ]
        case .monthlyScoreCalendar:
            result += [
                FabAction(title: "統計", systemImage: "chart.bar") { [weak self] in
                    self?.route = .monthlyScoreStats; self?.collapse()
                }
            ]
        case .moodThermometer:
            result += [
                FabAction(title: "記錄心情", systemImage: "plus.circle") { [weak self] in
                    self?.route = .navigate(.moodThermometer); self?.collapse()
                }
            ]
        }

        return result
    }

    // MARK: - FeatureID → 顯示文字 / 圖示

    func title(for feature: FeatureID) -> String {
        switch feature {
        case .calendar:               return "行事曆"
        case .diary:                  return "日記"
        case .wish:                   return "願望"
        case .ledger:                 return "記帳"
        case .settings:               return "設定"
        case .dailyLog:               return "每日紀錄"
        case .todoQuadrant:           return "待辦四象限"
        case .tomorrowRing:           return "時間圓環"
        case .bagRequired:            return "收拾書包"
        case .monthlyScoreCalendar:   return "本月結算"
        case .moodThermometer:        return "心情溫度計"
        }
    }

    func icon(for feature: FeatureID) -> String {
        switch feature {
        case .calendar:               return "calendar"
        case .diary:                  return "book"
        case .wish:                   return "sparkles"
        case .ledger:                 return "creditcard"
        case .settings:               return "gearshape"
        case .dailyLog:               return "square.and.pencil"
        case .todoQuadrant:           return "list.bullet.clipboard"
        case .tomorrowRing:           return "clock"
        case .bagRequired:            return "backpack"
        case .monthlyScoreCalendar:   return "calendar.badge.clock"
        case .moodThermometer:        return "heart.text.square"
        }
    }
}
