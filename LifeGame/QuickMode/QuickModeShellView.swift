import SwiftUI

/// 簡略模式頂層容器 — 左右滑動切換功能頁
struct QuickModeShellView: View {
    @ObservedObject var game: LifeGame
    @ObservedObject var moodStore: MoodStore
    let dailyLogStore: DailyLogStore

    @EnvironmentObject private var phoneModeStore: PhoneModeStore
    @EnvironmentObject private var fab: FabStore
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var wishStore: WishStore
    @EnvironmentObject private var ledgerStore: LedgerStore

    @State private var currentPageIndex: Int = 0
    @State private var navigationPath = NavigationPath()
    @State private var showSettings = false
    @State private var showAddCalendarEvent = false
    @State private var showAddDailyLog = false
    @State private var featureSettingsTarget: FeatureID?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .top) {
                // 主內容：TabView 頁面滑動
                TabView(selection: $currentPageIndex) {
                    ForEach(Array(phoneModeStore.quickPages.enumerated()), id: \.element.id) { index, page in
                        QuickPageView(page: page, dailyLogStore: dailyLogStore)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea(edges: .bottom)

                // 頂部導航列
                QuickModeTopBar(
                    currentPage: currentPage,
                    totalPages: phoneModeStore.quickPages.count,
                    currentIndex: currentPageIndex,
                    showSettings: $showSettings
                )
                .background(.ultraThinMaterial)
            }
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
        .onChange(of: currentPageIndex) { _, newIndex in
            updateFabContext(for: newIndex)
        }
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
            case .addRingItem, .quickAppendRing, .jumpToToday,
                 .addTodoToQuadrant, .todoEditMode,
                 .addWish, .editWishList, .addLedgerEntry, .viewLedgerChart,
                 .monthlyScoreStats:
                break
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .navigationBarTitleDisplayMode(.inline)
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
        .onAppear {
            updateFabContext(for: currentPageIndex)
        }
    }

    // MARK: - Helpers

    private var currentPage: QuickPage? {
        guard currentPageIndex < phoneModeStore.quickPages.count else { return nil }
        return phoneModeStore.quickPages[currentPageIndex]
    }

    private func updateFabContext(for index: Int) {
        guard index < phoneModeStore.quickPages.count else { return }
        let page = phoneModeStore.quickPages[index]
        fab.apply(context: .feature(page.featureType.featureID))
    }
}
