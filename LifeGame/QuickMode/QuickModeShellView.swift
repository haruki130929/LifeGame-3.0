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
    @EnvironmentObject private var appleSignIn: AppleSignInManager
    @Environment(StorageCoordinator.self) private var coordinator: StorageCoordinator?


    @State private var navigationPath = NavigationPath()
    @State private var showSettings = false
    @State private var showPageConfig = false
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
                    .coachAnchor(.quickSwipe)
                }

                // 右下角按鈕列
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Button {
                                showPageConfig = true
                            } label: {
                                Image(systemName: "rectangle.stack.badge.plus")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color(.tertiaryLabel))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                            }
                            .accessibilityLabel("編輯卡片")

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
                            .accessibilityLabel("設定")
                            .coachAnchor(.quickSettings)
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
                case .practiceDiary:
                    PracticeDiaryListView()
                case .questionModule:
                    QuestionModuleSettingsView()
                case .moduleEditor:
                    EmptyView()
                case .ganttChart:
                    GanttScreen()
                case .copingNotes:
                    CopingNotesView()
                case .communicationBoard:
                    CommunicationBoardView()
                }
            }
        }
        .sheet(isPresented: $showPageConfig) {
            NavigationStack {
                QuickPageConfigView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("完成") { showPageConfig = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .navigationBarTitleDisplayMode(.inline)
            }
            .environmentObject(appleSignIn)
            .environment(coordinator)
        }
    }

}
