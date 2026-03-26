import SwiftUI

/// 將 CardType 映射到實際的卡片 View
/// 所有依賴透過 @EnvironmentObject 取得
struct CardFactory: View {
    let cardType: CardType
    @Binding var ringSelectedID: UUID?

    init(cardType: CardType, ringSelectedID: Binding<UUID?> = .constant(nil)) {
        self.cardType = cardType
        self._ringSelectedID = ringSelectedID
    }

    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var game: LifeGame

    // 各卡片需要的 Store
    @EnvironmentObject private var todoStore: TodoQuadrantStore
    @State private var monthOffset = 0
    @State private var tomorrowPlan: TomorrowRingPlan = {
        if let saved: TomorrowRingPlan = StorageManager.load(TomorrowRingPlan.self, forKey: "tomorrow_ring_plan") {
            return saved
        }
        return .sample
    }()
    @State private var showCalendarScreen = false
    @State private var showTomorrowRingDetail = false
    @State private var showTodoQuadrantScreen = false
    @State private var showBagScreen = false
    @State private var showMonthlyScoreScreen = false

    private let cal = Calendar.current
    private let rangeProvider = CalendarRangeProvider()

    private var monthDate: Date {
        cal.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }

    var body: some View {
        switch cardType {
        case .calendar:
            CalendarCard(
                size: .medium,
                monthDate: monthDate,
                ranges: rangeProvider.ranges(from: calendarStore.events, in: monthDate),
                onPrevMonth: { monthOffset -= 1 },
                onNextMonth: { monthOffset += 1 },
                urgentImportantTasks: todoStore.items(in: .importantUrgent)
                    .filter { !$0.isDone }
                    .map { UrgentImportantTask(title: $0.title) }
            )
            .onTapGesture { showCalendarScreen = true }
            .navigationDestination(isPresented: $showCalendarScreen) {
                CalendarScreen()
            }

        case .todoQuadrant:
            TodoQuadrantCardLarge(store: todoStore)
                .onTapGesture { showTodoQuadrantScreen = true }
                .navigationDestination(isPresented: $showTodoQuadrantScreen) {
                    TodoQuadrantBoardView(store: todoStore)
                        .navigationTitle("待辦四象限")
                        .navigationBarTitleDisplayMode(.inline)
                }

        case .todayStatus:
            EmptyView()  // 已移除，保留 case 避免已存儲資料解碼失敗

        case .dailyLog:
            EmptyView()  // 已移除卡片，保留 case 避免已存儲資料解碼失敗

        case .tomorrowRing:
            TomorrowRingCard(size: .large, plan: $tomorrowPlan,
                             selectedSegmentID: $ringSelectedID,
                             onTap: { showTomorrowRingDetail = true })
                .navigationDestination(isPresented: $showTomorrowRingDetail) {
                    TomorrowRingDetailView(plan: $tomorrowPlan)
                }
                .onChange(of: tomorrowPlan) { _, newPlan in
                    StorageManager.save(newPlan, forKey: "tomorrow_ring_plan")
                }

        case .bagRequired:
            BagRequiredCardLarge(size: .medium)
                .onTapGesture { showBagScreen = true }
                .navigationDestination(isPresented: $showBagScreen) {
                    Bag_BackpackChecklistView()
                }

        case .monthlyScoreCalendar:
            MonthlyScoreCalendarCardLarge()
                .onTapGesture { showMonthlyScoreScreen = true }
                .navigationDestination(isPresented: $showMonthlyScoreScreen) {
                    MonthlyScorePageWrapper()
                }

        case .quickStart:
            DashboardCardContainer {
                VStack(alignment: .leading, spacing: 10) {
                    CardHeader(title: "快速開始", icon: "bolt")
                    Text("開始你的一天")
                        .foregroundStyle(.secondary)
                }
            }

        case .editCards:
            // editCards 在自訂切頁中不顯示
            EmptyView()
        }
    }
}
