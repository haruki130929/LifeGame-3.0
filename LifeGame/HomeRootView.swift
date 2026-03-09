import SwiftUI

struct HomeRootView: View {
    @ObservedObject var game: LifeGame
    @ObservedObject var moodStore: MoodStore
    @ObservedObject var slotCardStore: SlotCardConfigStore
    
    let dailyLogStore: DailyLogStore
    
    @EnvironmentObject private var fab: FabStore
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var wishStore: WishStore       // ✅ 新增
    @EnvironmentObject private var ledgerStore: LedgerStore   // ✅ 新增
    
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
                    // ✅ 預設顯示願望清單 tab
                    FinanceHubView(wishStore: wishStore, ledgerStore: ledgerStore, defaultTab: 0)
                case .ledger:
                    // ✅ 預設顯示記帳 tab
                    FinanceHubView(wishStore: wishStore, ledgerStore: ledgerStore, defaultTab: 1)
                case .settings:
                    SettingsView()
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
