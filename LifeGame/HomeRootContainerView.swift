import SwiftUI

/// ✅ 集中「建立 & 注入」所有功能 Store 的地方
/// HomeRootView 只管排版，不管依賴建立
struct HomeRootContainerView: View {
    
    // MARK: - Global / Feature Stores (EnvironmentObject)
    @StateObject private var theme = ThemeStore()
    @StateObject private var wishStore = WishStore()
    @StateObject private var ledgerStore = LedgerStore()
    @StateObject private var fab = FabStore()
    @StateObject private var calendarStore = CalendarStore()
    
    // MARK: - Local Feature Stores (原本在 HomeContentView 裡 @StateObject 的)
    @StateObject private var game = LifeGame()
    @StateObject private var moodStore = MoodStore()
    @StateObject private var slotCardStore = SlotCardConfigStore()
    
    // MARK: - Non-observable (不需要 UI 更新就維持 let)
    private let dailyLogStore = DailyLogStore()
    
    var body: some View {
        HomeRootView(
            game: game,
            moodStore: moodStore,
            slotCardStore: slotCardStore,
            dailyLogStore: dailyLogStore
        )
        .environmentObject(theme)
        .environmentObject(wishStore)
        .environmentObject(ledgerStore)
        .environmentObject(fab)
        .environmentObject(calendarStore)
    }
}
