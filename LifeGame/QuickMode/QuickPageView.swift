import SwiftUI

/// 簡略模式中的單一功能全螢幕頁面
struct QuickPageView: View {
    let page: QuickPage
    let dailyLogStore: DailyLogStore

    @EnvironmentObject private var wishStore: WishStore
    @EnvironmentObject private var ledgerStore: LedgerStore

    var body: some View {
        switch page.featureType {
        case .tomorrowRing:
            TomorrowRingPageWrapper()
        case .todo:
            TodoQuadrantPageWrapper()
        case .bag:
            Bag_BackpackChecklistView()
        case .mood:
            MoodThermometerScreen()
        case .dailyLog:
            DailyLogHistoryView(store: dailyLogStore)
        case .calendar:
            CalendarScreen()
        case .monthlyScore:
            MonthlyScorePageWrapper()
        case .diary:
            DiaryView()
        case .finance:
            FinanceHubView(wishStore: wishStore, ledgerStore: ledgerStore)
        case .ganttChart:
            GanttScreen()
        }
    }
}
