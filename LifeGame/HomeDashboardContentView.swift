import SwiftUI

/// 主頁面板內的「內容區」：卡片都放這裡（避免 HomeRootView 變胖）
struct HomeDashboardContentView: View {
    
    // ✅ 現在外面會告訴你目前在哪個分頁
    let selectedTab: HomeTab
    
    // Calendar data（目前只有工具頁先用到）
    @EnvironmentObject private var calendarStore: CalendarStore
    
    // Calendar UI State（給 CalendarCard 用）
    @State private var monthOffset = 0
    private let cal = Calendar.current
    private let rangeProvider = CalendarRangeProvider()
    private var monthDate: Date {
        cal.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }
    @State private var showCalendarScreen = false
    
    @StateObject private var todoStore = TodoQuadrantStore()
    
    /// 外框 tabs 的高度（因為內容要往下避開 tab）
    let tabHeight: CGFloat
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Spacer().frame(height: tabHeight + 10)
                
                // ✅ 每個 tab 顯示自己的卡片
                switch selectedTab {
                case .tools:
                    toolsCards
                    
                case .role:
                    comingSoonPlaceholder(title: "角色", icon: "person.crop.circle")

                case .growth:
                    comingSoonPlaceholder(title: "成長", icon: "chart.line.uptrend.xyaxis")

                case .help:
                    comingSoonPlaceholder(title: "幫助", icon: "lifepreserver")

                case .diary:
                    comingSoonPlaceholder(title: "日記", icon: "book")
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
        .navigationDestination(isPresented: $showCalendarScreen) {
            CalendarScreen()
        }
    }
    
    // MARK: - Tools cards (先把行事曆放工具頁，且用小卡片 grid)
    private var toolsCards: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 240), spacing: 12)],
            spacing: 12
        ) {
            CalendarCard(
                size: .medium, // ⭐ 小張卡片（如果你專案沒有 .medium，改成 .small）
                monthDate: monthDate,
                ranges: rangeProvider.ranges(
                    from: calendarStore.events,
                    in: monthDate
                ),
                onPrevMonth: { monthOffset -= 1 },
                onNextMonth: { monthOffset += 1 },
                urgentImportantTasks: [
                    UrgentImportantTask(title: "明天要交的作業"),
                    UrgentImportantTask(title: "回覆訊息")
                ]
            )
            .onTapGesture {
                showCalendarScreen = true
            }
            
            TodoQuadrantCardLarge(store: todoStore)
        }
    }
    
    // MARK: - Coming Soon
    private func comingSoonPlaceholder(title: String, icon: String) -> some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("\(title)功能即將推出")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
