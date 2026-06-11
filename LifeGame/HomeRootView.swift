import SwiftUI

struct HomeRootView: View {
    @ObservedObject var game: LifeGame
    @ObservedObject var moodStore: MoodStore
    @ObservedObject var slotCardStore: SlotCardConfigStore

    let dailyLogStore: DailyLogStore

    @EnvironmentObject private var fab: FabStore
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var wishStore: WishStore
    @EnvironmentObject private var ledgerStore: LedgerStore
    @EnvironmentObject private var moodHistory: MoodHistoryStore
    @EnvironmentObject private var moodSettings: MoodSettingsStore

    @State private var showAddCalendarEvent = false
    @State private var showAddDailyLog = false
    @State private var showMoodEdit = false
    @State private var featureSettingsTarget: FeatureID?
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            HomeContentView(
                game: game,
                moodStore: moodStore,
                slotCardStore: slotCardStore,
                dailyLogStore: dailyLogStore
            )
            .navigationDestination(for: FeatureID.self) { feature in
                switch feature {
                case .calendar:
                    CalendarScreen()
                case .diary:
                    DiaryView()
                case .wish:
                    FinanceHubView(wishStore: wishStore, ledgerStore: ledgerStore, defaultTab: 0)
                case .ledger:
                    FinanceHubView(wishStore: wishStore, ledgerStore: ledgerStore, defaultTab: 1)
                case .settings:
                    SettingsView()

                // ── 新增的卡片功能頁面 ──
                case .dailyLog:
                    DailyLogHistoryView(store: dailyLogStore)
                case .todoQuadrant:
                    TodoQuadrantPageWrapper()
                case .tomorrowRing:
                    TomorrowRingPageWrapper()
                case .bagRequired:
                    Bag_BackpackChecklistView()
                case .monthlyScoreCalendar:
                    MonthlyScorePageWrapper()
                case .moodThermometer:
                    MoodThermometerScreen()
                case .mandala:
                    MandalaChartScreen()
                case .practiceDiary:
                    PracticeDiaryListView()
                case .questionModule:
                    QuestionModuleSettingsView()
                case .moduleEditor:
                    EmptyView() // handled via sheet, not navigation
                case .ganttChart:
                    GanttScreen()
                }
            }
        }
        .fabFloatingOverlay()
        .onChange(of: fab.route) {
            guard let newRoute = fab.route else { return }

            switch newRoute {
            case .addCalendarEvent:
                showAddCalendarEvent = true
                fab.route = nil

            case .addDailyLog:
                showAddDailyLog = true
                fab.route = nil

            case .moodEdit:
                showMoodEdit = true
                fab.route = nil

            case .navigate(let feature):
                // 防止重複導航：只在根頁面時才 push
                if navigationPath.isEmpty {
                    navigationPath.append(feature)
                }
                fab.route = nil

            case .featureSettings(let feature):
                featureSettingsTarget = feature
                fab.route = nil

            // 功能頁面專用 route：
            // 已經在功能頁（navigationPath 不為空）→ 不攔截，讓功能頁接手
            // 在首頁 → 先導航到對應功能頁
            case .addRingItem, .editSchedule:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.tomorrowRing) ; fab.route = nil }
            case .jumpToToday:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.calendar) ; fab.route = nil }
            case .addTodoToQuadrant, .todoEditMode:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.todoQuadrant) ; fab.route = nil }
            case .addWish, .editWishList:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.wish) ; fab.route = nil }
            case .addLedgerEntry, .viewLedgerChart:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.ledger) ; fab.route = nil }
            case .monthlyScoreStats:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.monthlyScoreCalendar) ; fab.route = nil }
            case .addBagItem, .bagEditMode:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.bagRequired) ; fab.route = nil }
            case .addMandalaChart, .mandalaEditMode:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.mandala) ; fab.route = nil }
            case .addPracticeDiary, .practiceDiaryEditMode:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.practiceDiary) ; fab.route = nil }
            case .addQuestionModule, .questionModuleEditMode:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.questionModule) ; fab.route = nil }
            case .reviewDailyLog, .exportDailyLog:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.dailyLog) ; fab.route = nil }
            case .addQuestion, .questionEditMode:
                break // handled inside CustomModuleEditorView
            case .addGanttTask, .addMilestone, .toggleBuffer, .ganttBufferPercent, .deleteMilestoneMenu:
                break // handled inside GanttScreen
            }
        }
        .onChange(of: navigationPath) {
            if navigationPath.isEmpty {
                fab.popToRoot()
            }
        }
        .sheet(isPresented: $showAddCalendarEvent) {
            NewEventSheet { title, start, end, colorHex, frequency, repeatCount in
                Task {
                    await calendarStore.add(title: title, start: start, end: end, colorHex: colorHex, frequency: frequency, repeatCount: repeatCount)
                }
            }
        }
        .sheet(isPresented: $showAddDailyLog) {
            NavigationStack {
                DailyLogEditorView(mode: .add, store: dailyLogStore)
            }
        }
        .sheet(item: $featureSettingsTarget) { feature in
            NavigationStack {
                FeatureSettingsRouter(feature: feature)
            }
        }
        .sheet(isPresented: $showMoodEdit) {
            MoodEditView()
                .environmentObject(moodHistory)
                .environmentObject(moodSettings)
        }
    }
}

// MARK: - 輕量包裝器已移至 QuickMode/FeaturePageWrappers.swift（共用）
