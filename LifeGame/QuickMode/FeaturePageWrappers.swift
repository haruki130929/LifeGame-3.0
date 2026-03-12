import SwiftUI

// MARK: - 輕量包裝器（供 Quick Mode 與 navigationDestination 共用）

/// 待辦四象限 — 包裝 TodoQuadrantBoardView，自帶 store
struct TodoQuadrantPageWrapper: View {
    @StateObject private var store = TodoQuadrantStore()

    var body: some View {
        TodoQuadrantBoardView(store: store)
            .navigationTitle("待辦四象限")
    }
}

/// 時間圓環 — 包裝 TomorrowRingDetailView，自帶 plan state
struct TomorrowRingPageWrapper: View {
    @State private var plan: TomorrowRingPlan = {
        if let saved: TomorrowRingPlan = StorageManager.load(TomorrowRingPlan.self, forKey: "tomorrow_ring_plan") {
            return saved
        }
        return .sample
    }()

    var body: some View {
        TomorrowRingDetailView(plan: $plan)
            .navigationTitle("時間圓環")
            .onChange(of: plan) { _, newPlan in
                StorageManager.save(newPlan, forKey: "tomorrow_ring_plan")
            }
    }
}

/// 本月結算 — 包裝 MonthlyScoreCalendarCardLarge 成全頁
struct MonthlyScorePageWrapper: View {
    var body: some View {
        ScrollView {
            MonthlyScoreCalendarCardLarge()
                .padding()
        }
        .navigationTitle("本月結算")
    }
}
