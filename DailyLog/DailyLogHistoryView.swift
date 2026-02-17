import SwiftUI
import Charts

struct DailyLogHistoryView: View {
    
    // ✅ 只留一個 store（外部傳進來）
    @ObservedObject var store: DailyLogStore
    
    @EnvironmentObject var fab: FabStore
    
    @State private var presentingEditor = false
    @State private var editingEntry = DailyLogEntry()
    
    var body: some View {
        List {
            
            Section("趨勢") {
                DailyMetricLineChart(
                    title: "情緒高低",
                    points: trendPoints,
                    x: \.date,
                    y: \.mood,
                    yDomain: 0...10
                )
                
                DailyMetricLineChart(
                    title: "疲勞程度",
                    points: trendPoints,
                    x: \.date,
                    y: \.fatigue,
                    yDomain: 0...10
                )
                
                DailyMetricLineChart(
                    title: "焦慮程度",
                    points: trendPoints,
                    x: \.date,
                    y: \.anxiety,
                    yDomain: 0...10
                )
                
                DailyMetricLineChart(
                    title: "睡眠品質",
                    points: trendPoints,
                    x: \.date,
                    y: \.sleepQuality,
                    yDomain: 0...10
                )
            }
            
            Section("紀錄") {
                ForEach(store.entries) { entry in
                    NavigationLink {
                        DailyLogEditorView(entry: entry) { updated in
                            store.upsert(updated)
                        }
                    } label: {
                        DailyLogHistoryRow(entry: entry)
                    }
                }
                .onDelete(perform: store.delete)
            }
        }
        .navigationTitle("每日紀錄")
        .onAppear {
            fab.setActions([
                FabAction(title: "寫新日記", systemImage: "plus") {
                    createNewOrEditToday()
                },
                FabAction(title: "搜尋日記", systemImage: "magnifyingglass") {
                    print("搜尋功能")
                }
            ])
        }
        .sheet(isPresented: $presentingEditor) {
            NavigationStack {
                DailyLogEditorView(entry: editingEntry) { updated in
                    store.upsert(updated)
                    presentingEditor = false
                }
            }
        }
    }
    
    // ✅ 這個要放在 struct 裡、body 外面（不能塞在 body 裡）
    private var trendPoints: [TrendPoint] {
        let logs = store.entries.sorted { $0.date < $1.date }
        return logs.suffix(14).map { log in
            TrendPoint(
                date: log.date,
                mood: log.overallMoodScore,
                fatigue: log.fatigueScore,
                anxiety: log.anxietyScore,
                sleepQuality: sleepQualityScore(from: log.sleepQuality)
            )
        }
    }
    
    private func sleepQualityScore(from q: SleepQuality) -> Int {
        switch q {
        case .good:   return 8
        case .normal: return 5
        case .bad:    return 2
        }
    }
    
    private func createNewOrEditToday() {
        editingEntry = store.addToday()
        presentingEditor = true
    }
}

private struct DailyLogHistoryRow: View {
    let entry: DailyLogEntry
    
    var body: some View {
        HStack {
            Text(entry.date, format: .dateTime.year().month().day())
                .font(.headline)
            Spacer()
            Text(entry.weather.rawValue)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let mood: Int
    let fatigue: Int
    let anxiety: Int
    let sleepQuality: Int
}
