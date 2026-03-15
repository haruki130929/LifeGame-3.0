import SwiftUI

/// 簡略模式頂層容器 — 卡片堆疊刷掉互動
struct QuickModeShellView: View {
    @ObservedObject var game: LifeGame
    @ObservedObject var moodStore: MoodStore
    let dailyLogStore: DailyLogStore

    @EnvironmentObject private var phoneModeStore: PhoneModeStore
    @EnvironmentObject private var fab: FabStore
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var wishStore: WishStore
    @EnvironmentObject private var ledgerStore: LedgerStore

    @State private var navigationPath = NavigationPath()
    @State private var showSettings = false
    @State private var completedCount = 0
    @State private var topPage: QuickPage?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // 深色背景
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 頂部進度列
                    QuickModeTopBar(
                        completedCount: completedCount,
                        totalCount: phoneModeStore.quickPages.count
                    )

                    // 卡片堆疊
                    CardStackView(
                        pages: phoneModeStore.quickPages,
                        dailyLogStore: dailyLogStore,
                        onTopCardChanged: { page in
                            topPage = page
                        },
                        onProgressChanged: { completed, _ in
                            completedCount = completed
                        }
                    )
                }

                // 右下角設定按鈕（取代 FAB）
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                                .background(Color(.tertiaryLabel))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
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
                case .mandala:
                    MandalaChartScreen()
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
