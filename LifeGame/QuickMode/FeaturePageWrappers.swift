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
    @EnvironmentObject private var fab: FabStore
    @State private var showStats = false
    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MonthlyScoreCalendarCardLarge()
                MonthlyScoreChartView()
            }
            .padding()
        }
        .navigationTitle("本月結算")
        .fabMenu([
            FabAction(title: "統計", systemImage: "chart.bar") { showStats = true },
            FabAction(title: "設定", systemImage: "gearshape") { showSettings = true }
        ])
        .sheet(isPresented: $showStats) {
            NavigationStack {
                MonthlyScoreStatsView()
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                MonthlyScoreSettingsView()
            }
        }
    }
}

/// 本月結算統計（暫用佔位）
private struct MonthlyScoreStatsView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("本月統計") {
                let records = currentMonthRecords
                HStack {
                    Text("已記錄天數")
                    Spacer()
                    Text("\(records.count) 天").bold()
                }
                HStack {
                    Text("平均分數")
                    Spacer()
                    let avg = records.isEmpty ? 0 : records.map(\.median).reduce(0, +) / records.count
                    Text("\(avg)").bold()
                }
                HStack {
                    Text("最高分")
                    Spacer()
                    Text("\(records.map(\.median).max() ?? 0)").bold()
                }
                HStack {
                    Text("最低分")
                    Spacer()
                    Text("\(records.map(\.median).min() ?? 0)").bold()
                }
            }
        }
        .navigationTitle("統計")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") { dismiss() }
            }
        }
    }

    private var currentMonthRecords: [DayRecord] {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        return historyStore.records(in: start)
    }
}
