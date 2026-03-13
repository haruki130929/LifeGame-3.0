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

            case .navigate(let feature):
                navigationPath.append(feature)
                fab.route = nil

            case .featureSettings(let feature):
                featureSettingsTarget = feature
                fab.route = nil

            // 功能頁面專用 route，由各自的 View 處理
            case .addRingItem, .quickAppendRing, .jumpToToday,
                 .addTodoToQuadrant, .todoEditMode,
                 .addWish, .editWishList, .addLedgerEntry, .viewLedgerChart,
                 .monthlyScoreStats:
                break
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
    }
}

// MARK: - 輕量包裝器已移至 QuickMode/FeaturePageWrappers.swift（共用）
