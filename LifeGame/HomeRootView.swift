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
            // 已經在功能頁（navigationPath 不為空）→ 不做事，讓功能頁接手
            // 在首頁 → 先導航到對應功能頁
            case .addRingItem, .editSchedule:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.tomorrowRing) }
            case .jumpToToday:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.calendar) }
            case .addTodoToQuadrant, .todoEditMode:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.todoQuadrant) }
            case .addWish, .editWishList:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.wish) }
            case .addLedgerEntry, .viewLedgerChart:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.ledger) }
            case .monthlyScoreStats:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.monthlyScoreCalendar) }
            case .addBagItem, .bagEditMode:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.bagRequired) }
            case .addMandalaChart, .mandalaEditMode:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.mandala) }
            case .addPracticeDiary, .practiceDiaryEditMode:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.practiceDiary) }
            case .addQuestionModule, .questionModuleEditMode:
                if navigationPath.isEmpty { navigationPath.append(FeatureID.questionModule) }
            }
        }
        .onChange(of: navigationPath) {
            if navigationPath.isEmpty {
                fab.popToRoot()
            }
        }
        .sheet(isPresented: $showAddCalendarEvent) {
            AddCalendarEventView(
                store: calendarStore,
                calendar: Calendar.current
            )
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
        }
    }
}

// MARK: - 輕量包裝器已移至 QuickMode/FeaturePageWrappers.swift（共用）
