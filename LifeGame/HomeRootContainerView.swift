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
    @EnvironmentObject private var timeSlotNameStore: TimeSlotNameStore

    // MARK: - 功能頁專用 Store（從 MyApp 移入，只在功能頁面使用時才需要）
    @StateObject private var calendarSettings = CalendarSettingsStore()
    @StateObject private var moodHistory = MoodHistoryStore()
    @StateObject private var ringSettings = TomorrowRingSettingsStore()
    @StateObject private var weeklyScheduleStore = WeeklyScheduleStore()
    @StateObject private var tomorrowRingStore = TomorrowRingStore()
    @StateObject private var moduleStore = QuestionModuleStore()
    @StateObject private var historyStore = HistoryStore()
    @StateObject private var moodSettings = MoodSettingsStore()
    @StateObject private var mandalaStore = MandalaStore()
    @StateObject private var todoStore = TodoQuadrantStore()
    @StateObject private var updateChecker = AppUpdateChecker()
    @StateObject private var characterStore = CharacterStore()

    // MARK: - Non-observable (不需要 UI 更新就維持 let)
    private let dailyLogStore = DailyLogStore()

    var body: some View {
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
                    .environmentObject(calendarSettings)
                    .environmentObject(moodHistory)
                    .environmentObject(ringSettings)
                    .environmentObject(weeklyScheduleStore)
                    .environmentObject(tomorrowRingStore)
                    .environmentObject(moduleStore)
                    .environmentObject(historyStore)
                    .environmentObject(moodSettings)
                    .environmentObject(mandalaStore)
                    .environmentObject(todoStore)
                    .environmentObject(updateChecker)
                    .environmentObject(characterStore)
                }
            }
        }
        .overlayPreferenceValue(CoachAnchorKey.self) { anchors in
            GeometryReader { proxy in
                CoachMarkOverlay(anchors: anchors, proxy: proxy)
            }
            .ignoresSafeArea()
        }
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
        // 功能頁專用 Store（從 MyApp 移入）
        .environmentObject(calendarSettings)
        .environmentObject(moodHistory)
        .environmentObject(ringSettings)
                    .environmentObject(weeklyScheduleStore)
        .environmentObject(tomorrowRingStore)
        .environmentObject(moduleStore)
        .environmentObject(historyStore)
        .environmentObject(moodSettings)
        .environmentObject(mandalaStore)
        .environmentObject(todoStore)
        .environmentObject(updateChecker)
        .environmentObject(characterStore)
        // Mac Catalyst：內容滿版填滿視窗，不限制寬度、不留左右黑邊（其他平台 no-op）
        // 若日後想改回置中留白，把 .infinity 換回想要的寬度（例如 1366）即可。
        .macCenteredContent(maxWidth: .infinity)
    }
}
