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
                    DailyLogExpandedRow(entry: entry) {
                        // 編輯：用同一個 sheet 機制（你原本就有 presentingEditor / editingEntry）
                        editingEntry = entry
                        presentingEditor = true
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            // 這裡最簡單：找 index 刪掉
                            if let idx = store.entries.firstIndex(where: { $0.id == entry.id }) {
                                store.delete(at: IndexSet(integer: idx))
                            }
                        } label: {
                            Label("刪除", systemImage: "trash")
                        }
                        
                        Button {
                            editingEntry = entry
                            presentingEditor = true
                        } label: {
                            Label("編輯", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
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

private struct DailyLogExpandedRow: View {
    let entry: DailyLogEntry
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // 日期 + 天氣 + 編輯
            HStack(alignment: .firstTextBaseline) {
                Text(entry.date, format: .dateTime.year().month().day())
                    .font(.headline)
                
                Spacer()
                
                Text(entry.weather.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.subheadline)
                        .padding(8)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            
            // 4 個重點指標（你趨勢圖也在用這四個）
            HStack(spacing: 12) {
                metric("情緒", value: entry.overallMoodScore)
                metric("疲勞", value: entry.fatigueScore)
                metric("焦慮", value: entry.anxietyScore)
                metric("睡眠", value: sleepQualityScore(entry.sleepQuality))
            }
            .font(.subheadline)
            
            // 備註（有寫才顯示，避免卡片太長）
            if !entry.specialObservation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(entry.specialObservation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(6)          // 你想更長就調大
            }
        }
        .padding(.vertical, 10)
    }
    
    private func metric(_ title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).foregroundStyle(.secondary)
            Text("\(value)/10").font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func sleepQualityScore(_ q: SleepQuality) -> Int {
        switch q {
        case .good: return 8
        case .normal: return 5
        case .bad: return 2
        }
    }
}
