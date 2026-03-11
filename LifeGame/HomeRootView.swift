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

            case .navigate(let feature):
                navigationPath.append(feature)
                fab.route = nil

            // 功能頁面專用 route，由各自的 View 處理
            case .addRingItem, .quickAppendRing, .jumpToToday,
                 .addTodoToQuadrant, .todoEditMode:
                break
            }
        }
        .sheet(isPresented: $showAddCalendarEvent) {
            AddCalendarEventView(
                store: calendarStore,
                calendar: Calendar.current
            )
        }
    }
}

// MARK: - 輕量包裝器（讓 navigationDestination 可以擁有自己的 @State / @StateObject）

/// 待辦四象限 — 包裝 TodoQuadrantBoardView，自帶 store
private struct TodoQuadrantPageWrapper: View {
    @StateObject private var store = TodoQuadrantStore()

    var body: some View {
        TodoQuadrantBoardView(store: store)
            .navigationTitle("待辦四象限")
    }
}

/// 時間圓環 — 包裝 TomorrowRingDetailView，自帶 plan state
private struct TomorrowRingPageWrapper: View {
    @State private var plan: TomorrowRingPlan = {
        if let saved: TomorrowRingPlan = StorageManager.load(TomorrowRingPlan.self, forKey: "tomorrow_ring_plan") {
            return saved
        }
        return .sample
    }()

    var body: some View {
        TomorrowRingDetailView(plan: $plan)
            .navigationTitle("時間圓環")
            .onChange(of: plan) { _, newPlan in
                StorageManager.save(newPlan, forKey: "tomorrow_ring_plan")
            }
    }
}

/// 本月結算 — 包裝 MonthlyScoreCalendarCardLarge 成全頁
private struct MonthlyScorePageWrapper: View {
    var body: some View {
        ScrollView {
            MonthlyScoreCalendarCardLarge()
                .padding()
        }
        .navigationTitle("本月結算")
    }
}
