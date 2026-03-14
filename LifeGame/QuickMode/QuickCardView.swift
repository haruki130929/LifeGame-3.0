import SwiftUI

/// 全螢幕功能卡片 — 統一背景色，嵌入完整功能頁面
struct QuickCardView: View {
    let page: QuickPage
    let dailyLogStore: DailyLogStore

    @EnvironmentObject private var wishStore: WishStore
    @EnvironmentObject private var ledgerStore: LedgerStore

    var body: some View {
        VStack(spacing: 0) {
            // ── 卡片名稱 ──
            HStack(spacing: 8) {
                Image(systemName: page.featureType.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(page.featureType.title)
                    .font(.system(size: 15, weight: .bold))
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 6)

            // ── 功能內容 ──
            featureContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .navigationTitle("")
                .navigationBarHidden(true)
        }
        .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color(.separator), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 3)
    }

    // MARK: - 功能內容

    @ViewBuilder
    private var featureContent: some View {
        switch page.featureType {
        case .tomorrowRing:
            QuickTomorrowRingView()
        case .todo:
            TodoQuadrantPageWrapper()
        case .bag:
            QuickBagView()
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
        }
    }
}
