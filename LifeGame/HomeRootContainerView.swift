import SwiftUI

/// 集中「建立 & 注入」所有功能 Store 的地方
/// HomeRootView 只管排版，不管依賴建立
///
/// ⚠️ theme / wishStore / ledgerStore / fab / calendarStore
///   已由 MyApp 建立並注入 → 這裡只用 @EnvironmentObject 讀取，
///   不重新 @StateObject，避免產生第二份實例導致主題等設定失效。
struct HomeRootContainerView: View {

    // MARK: - 由 MyApp 注入的全域 Store（不要重複建立！）
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var wishStore: WishStore
    @EnvironmentObject private var ledgerStore: LedgerStore
    @EnvironmentObject private var fab: FabStore
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var phoneModeStore: PhoneModeStore
    @EnvironmentObject private var coachMarkStore: CoachMarkStore

    // MARK: - Local Feature Stores (原本在 HomeContentView 裡 @StateObject 的)
    @StateObject private var game = LifeGame()
    @StateObject private var moodStore = MoodStore()
    @StateObject private var slotCardStore = SlotCardConfigStore()
    @StateObject private var monthlyScoreStore = MonthlyScoreStore()
    @StateObject private var customTabStore = CustomTabStore()
    @StateObject private var timeSlotNameStore = TimeSlotNameStore()

    // MARK: - Non-observable (不需要 UI 更新就維持 let)
    private let dailyLogStore = DailyLogStore()

    var body: some View {
        ZStack {
            Group {
                if AppLayout.isIPad {
                    fullModeView
                } else {
                    switch phoneModeStore.mode {
                    case .full:
                        fullModeView
                    case .quick:
                        QuickModeShellView(
                            game: game,
                            moodStore: moodStore,
                            dailyLogStore: dailyLogStore
                        )
                        .environmentObject(monthlyScoreStore)
                        .environmentObject(customTabStore)
                        .environmentObject(timeSlotNameStore)
                        .environmentObject(game)
                        .environmentObject(moodStore)
                    }
                }
            }

            CoachMarkOverlay()
        }
        .coordinateSpace(name: "coachRoot")
        .onAppear {
            let isQuick = !AppLayout.isIPad && phoneModeStore.mode == .quick
            coachMarkStore.startIfNeeded(isQuickMode: isQuick)
        }
    }

    private var fullModeView: some View {
        HomeRootView(
            game: game,
            moodStore: moodStore,
            slotCardStore: slotCardStore,
            dailyLogStore: dailyLogStore
        )
        // 只注入此處獨有的 Store；其餘自動繼承自 MyApp
        .environmentObject(monthlyScoreStore)
        .environmentObject(customTabStore)
        .environmentObject(timeSlotNameStore)
        .environmentObject(game)
        .environmentObject(moodStore)
    }
}
