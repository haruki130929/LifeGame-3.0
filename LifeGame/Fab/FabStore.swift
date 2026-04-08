import SwiftUI
import Combine

struct FabAction: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    var route: FabStore.Route? = nil
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
        case editSchedule
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
        // ── 心情溫度計專用 ──
        case moodEdit
        // ── 整理書包專用 ──
        case addBagItem
        case bagEditMode
        // ── 曼陀羅圖表專用 ──
        case addMandalaChart
        case mandalaEditMode
        // ── 練習日記專用 ──
        case addPracticeDiary
        case practiceDiaryEditMode
        // ── 問題模組專用 ──
        case addQuestionModule
        case questionModuleEditMode
        // ── 模組編輯器專用 ──
        case addQuestion
        case questionEditMode
        // ── 功能設定 ──
        case featureSettings(FeatureID)

        var id: String {
            switch self {
            case .addCalendarEvent:         return "addCalendarEvent"
            case .jumpToToday:              return "jumpToToday"
            case .navigate(let f):          return "navigate-\(f)"
            case .addRingItem:              return "addRingItem"
            case .editSchedule:             return "editSchedule"
            case .addTodoToQuadrant(let q): return "addTodo-\(q.rawValue)"
            case .todoEditMode:             return "todoEditMode"
            case .addDailyLog:              return "addDailyLog"
            case .addWish:                  return "addWish"
            case .editWishList:             return "editWishList"
            case .addLedgerEntry:           return "addLedgerEntry"
            case .viewLedgerChart:          return "viewLedgerChart"
            case .monthlyScoreStats:        return "monthlyScoreStats"
            case .moodEdit:                 return "moodEdit"
            case .addBagItem:               return "addBagItem"
            case .bagEditMode:              return "bagEditMode"
            case .addMandalaChart:          return "addMandalaChart"
            case .mandalaEditMode:          return "mandalaEditMode"
            case .addPracticeDiary:         return "addPracticeDiary"
            case .practiceDiaryEditMode:    return "practiceDiaryEditMode"
            case .addQuestionModule:        return "addQuestionModule"
            case .questionModuleEditMode:   return "questionModuleEditMode"
            case .addQuestion:             return "addQuestion"
            case .questionEditMode:        return "questionEditMode"
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
    @Published var currentFeatures: [FeatureID] = []

    private var featureStack: [[FabAction]] = []
    private var lastHomeFeatures: [FeatureID] = []

    /// 是否在功能頁（有 push 過 actions）
    var isOnFeaturePage: Bool { featureStack.count > 1 }

    func setRootActions(_ actions: [FabAction]) {
        if featureStack.isEmpty {
            featureStack = [actions]
        } else if featureStack.indices.contains(0) {
            featureStack[0] = actions
        }
        // 只有在根層級時才更新顯示的 actions；功能頁 push 過 actions 時保留功能頁的
        if featureStack.count <= 1 {
            self.actions = actions
            hideSubMenu()
            collapse()
        }
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
        // 回到根層級時清除 currentFeatures，讓 refreshFabMenu 恢復主頁面功能列表
        if featureStack.count <= 1 {
            currentFeatures = lastHomeFeatures
        }
        hideSubMenu()
        collapse()
    }

    /// 返回主頁時強制清除所有功能頁的 action stack
    func popToRoot() {
        guard featureStack.count > 1 else { return }
        while featureStack.count > 1 {
            featureStack.removeLast()
        }
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
            lastHomeFeatures = features
            // 如果已經在功能頁（stack 有 push），不要覆蓋 currentFeatures
            if featureStack.count <= 1 {
                currentFeatures = features
            }
            setRootActions(makeHomeActions(features: features))
        case let .feature(feature):
            currentFeatures = [feature]
            isHidden = false
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
                FabAction(title: "設定", systemImage: "gearshape", route: .featureSettings(feature)) { [weak self] in
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
                FabAction(title: "新增行程", systemImage: "calendar.badge.plus", route: .addCalendarEvent) { [weak self] in
                    self?.route = .addCalendarEvent; self?.collapse()
                }
            ]
        case .diary:
            result += [
                FabAction(title: "新增日記", systemImage: "square.and.pencil", route: .navigate(.diary)) { [weak self] in
                    self?.route = .navigate(.diary); self?.collapse()
                }
            ]
        case .ledger:
            result += [
                FabAction(title: "新增收支", systemImage: "plus.circle", route: .addLedgerEntry) { [weak self] in
                    self?.route = .addLedgerEntry; self?.collapse()
                },
                FabAction(title: "檢視圖表", systemImage: "chart.pie", route: .viewLedgerChart) { [weak self] in
                    self?.route = .viewLedgerChart; self?.collapse()
                }
            ]
        case .wish:
            result += [
                FabAction(title: "新增願望", systemImage: "sparkles", route: .addWish) { [weak self] in
                    self?.route = .addWish; self?.collapse()
                },
                FabAction(title: "編輯", systemImage: "pencil", route: .editWishList) { [weak self] in
                    self?.route = .editWishList; self?.collapse()
                }
            ]
        case .settings:
            result += [
                FabAction(title: "偏好設定", systemImage: "gearshape", route: .navigate(.settings)) { [weak self] in
                    self?.route = .navigate(.settings); self?.collapse()
                }
            ]
        case .dailyLog:
            result += [
                FabAction(title: "新增日記", systemImage: "plus.circle", route: .addDailyLog) { [weak self] in
                    self?.route = .addDailyLog; self?.collapse()
                },
                FabAction(title: "設定", systemImage: "gearshape", route: .featureSettings(.dailyLog)) { [weak self] in
                    self?.route = .featureSettings(.dailyLog); self?.collapse()
                }
            ]
        case .todoQuadrant:
            result += [
                FabAction(title: "新增待辦事項", systemImage: "plus.circle") { [weak self] in
                    guard let self else { return }
                    self.subActions = TodoQuadrant.allCases.map { q in
                        FabAction(title: q.title, systemImage: q.fabIcon, route: .addTodoToQuadrant(q)) { [weak self] in
                            self?.route = .addTodoToQuadrant(q); self?.collapse()
                        }
                    }
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        self.showSubMenu = true
                    }
                },
                FabAction(title: "編輯", systemImage: "pencil", route: .todoEditMode) { [weak self] in
                    self?.route = .todoEditMode; self?.collapse()
                }
            ]
        case .tomorrowRing:
            result += [
                FabAction(title: "新增時段", systemImage: "plus.circle", route: .addRingItem) { [weak self] in
                    self?.route = .addRingItem; self?.collapse()
                },
                FabAction(title: "課表", systemImage: "calendar.badge.clock", route: .editSchedule) { [weak self] in
                    self?.route = .editSchedule
                    // 不呼叫 collapse()，讓 sheet 先呈現，sheet 的 onDismiss 會自然蓋住 FAB
                }
            ]
        case .bagRequired:
            result += [
                FabAction(title: "新增物品", systemImage: "plus.circle", route: .addBagItem) { [weak self] in
                    self?.route = .addBagItem; self?.collapse()
                },
                FabAction(title: "編輯", systemImage: "pencil", route: .bagEditMode) { [weak self] in
                    self?.route = .bagEditMode; self?.collapse()
                }
            ]
        case .monthlyScoreCalendar:
            result += [
                FabAction(title: "統計", systemImage: "chart.bar", route: .monthlyScoreStats) { [weak self] in
                    self?.route = .monthlyScoreStats; self?.collapse()
                }
            ]
        case .moodThermometer:
            result += [
                FabAction(title: "編輯", systemImage: "pencil.circle", route: .moodEdit) { [weak self] in
                    self?.route = .moodEdit; self?.collapse()
                }
            ]
        case .mandala:
            result += [
                FabAction(title: "新增圖表", systemImage: "plus.circle", route: .addMandalaChart) { [weak self] in
                    self?.route = .addMandalaChart; self?.collapse()
                },
                FabAction(title: "編輯", systemImage: "pencil", route: .mandalaEditMode) { [weak self] in
                    self?.route = .mandalaEditMode; self?.collapse()
                }
            ]
        case .practiceDiary:
            result += [
                FabAction(title: "新增練習日記", systemImage: "plus.circle", route: .addPracticeDiary) { [weak self] in
                    self?.route = .addPracticeDiary; self?.collapse()
                },
                FabAction(title: "編輯", systemImage: "pencil", route: .practiceDiaryEditMode) { [weak self] in
                    self?.route = .practiceDiaryEditMode; self?.collapse()
                }
            ]
        case .questionModule:
            result += [
                FabAction(title: "新增模組", systemImage: "plus.circle", route: .addQuestionModule) { [weak self] in
                    self?.route = .addQuestionModule; self?.collapse()
                },
                FabAction(title: "排序", systemImage: "arrow.up.arrow.down", route: .questionModuleEditMode) { [weak self] in
                    self?.route = .questionModuleEditMode; self?.collapse()
                }
            ]
        case .moduleEditor:
            result += [
                FabAction(title: "新增問題", systemImage: "plus.circle", route: .addQuestion) { [weak self] in
                    self?.route = .addQuestion; self?.collapse()
                },
                FabAction(title: "排序", systemImage: "arrow.up.arrow.down", route: .questionEditMode) { [weak self] in
                    self?.route = .questionEditMode; self?.collapse()
                }
            ]
        }

        return result
    }

    // MARK: - FeatureID → 顯示文字 / 圖示

    func title(for feature: FeatureID) -> String {
        switch feature {
        case .calendar:               return L10n.Title.calendar
        case .diary:                  return L10n.Title.diary
        case .wish:                   return L10n.Title.wish
        case .ledger:                 return L10n.Title.ledger
        case .settings:               return L10n.Title.settings
        case .dailyLog:               return L10n.Title.dailyLog
        case .todoQuadrant:           return L10n.Title.todoQuadrant
        case .tomorrowRing:           return L10n.Title.tomorrowRing
        case .bagRequired:            return L10n.Title.bagRequired
        case .monthlyScoreCalendar:   return L10n.Title.monthlyScore
        case .moodThermometer:        return L10n.Title.moodThermometer
        case .mandala:                return L10n.Title.mandala
        case .practiceDiary:          return "練習日記"
        case .questionModule:         return "問題模組"
        case .moduleEditor:           return "編輯模組"
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
        case .mandala:                return "square.grid.3x3"
        case .practiceDiary:          return "pencil.and.list.clipboard"
        case .questionModule:         return "square.grid.2x2"
        case .moduleEditor:           return "pencil.and.list.clipboard"
        }
    }
}
