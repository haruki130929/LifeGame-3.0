import SwiftUI
import Charts

struct DailyLogHistoryView: View {
    
    // ✅ 只留一個 store（外部傳進來）
    @ObservedObject var store: DailyLogStore
    
    @State private var editingEntry: DailyLogEntry? = nil
    @State private var presentingReview = false
    
    var body: some View {
        List {
            trendSection
            entriesSection
        }
        .navigationTitle("每日紀錄")
        .sheet(item: $editingEntry) { entry in
            NavigationStack {
                DailyLogEditorView(entry: entry) { updated in
                    store.upsert(updated)
                    editingEntry = nil
                }
            }
        }
        .sheet(isPresented: $presentingReview) {
            DailyLogReviewRangeSheet(allEntries: store.entries)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    presentingReview = true
                } label: {
                    Label("檢視", systemImage: "eye")
                }
            }
        }
        .fabMenu(dailyLogActions)
    }
}

// MARK: - Sections
private extension DailyLogHistoryView {
    
    var trendSection: some View {
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
    }
    
    var entriesSection: some View {
        Section("紀錄") {
            ForEach(store.entries) { entry in
                DailyLogExpandedRow(entry: entry) {
                    editingEntry = entry
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        if let idx = store.entries.firstIndex(where: { $0.id == entry.id }) {
                            store.delete(at: IndexSet(integer: idx))
                        }
                    } label: {
                        Label("刪除", systemImage: "trash")
                    }
                    
                    Button {
                        editingEntry = entry
                    } label: {
                        Label("編輯", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
    }
}

// MARK: - Trend
private extension DailyLogHistoryView {
    
    var trendPoints: [TrendPoint] {
        let logs = store.entries.sorted { $0.date < $1.date }
        return logs.suffix(14).map { log in
            TrendPoint(
                date: log.date,
                mood: log.overallMoodScore,
                fatigue: log.fatigueScore,
                anxiety: log.anxietyScore,
                sleepQuality: sleepQualityScore(log.sleepQuality)
            )
        }
    }
    
    func sleepQualityScore(_ q: SleepQuality) -> Int {
        switch q {
        case .good:   return 8
        case .normal: return 5
        case .bad:    return 2
        }
    }
}

// MARK: - TrendPoint
struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let mood: Int
    let fatigue: Int
    let anxiety: Int
    let sleepQuality: Int
}

// MARK: - Expanded Row (新版摘要：起床/上床/睡眠/原因數/照片數)
private struct DailyLogExpandedRow: View {
    let entry: DailyLogEntry
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            headerLine
            
            timeLine
            
            scoresLine
            
            sleepLine
            
            tagsLine
            
            observationPreview
        }
        .padding(.vertical, 10)
    }
    
    // MARK: subviews
    
    private var headerLine: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(entry.date, format: .dateTime.year().month().day())
                .font(.headline)
            
            Spacer()
            
            Text(entry.weather.rawValue)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.subheadline)
                    .padding(8)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var timeLine: some View {
        HStack(spacing: 12) {
            Label("起床 \(wakeText)", systemImage: "sunrise")
            Label("上床 \(bedText)", systemImage: "bed.double")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    
    private var scoresLine: some View {
        HStack(spacing: 12) {
            metric("情緒", value: entry.overallMoodScore)
            metric("焦慮", value: entry.anxietyScore)
            metric("疲勞", value: entry.fatigueScore)
        }
        .font(.subheadline)
    }
    
    private var sleepLine: some View {
        HStack(spacing: 12) {
            chip("睡 \(sleepHoursText)")
            chip(shortSleepQualityText)
        }
        .font(.footnote)
    }
    
    private var sleepHoursText: String {
        switch entry.sleepHours {
        case .unknown:
            return "忘記"
        case .value(let h):
            return "\(String(format: "%.1f", h))h"
        }
    }
    
    private var tagsLine: some View {
        HStack(spacing: 10) {
            if entry.moodChangeType == .higher {
                chip("情緒原因 \(entry.moodChangeReasons.count)")
            }
            if entry.anxietyLevel != .none {
                chip("焦慮原因 \(entry.anxietyReasons.count)")
            }
            
            // ✅ 新版：衝動行為（程度可複選）
            if !entry.impulseSeverities.isEmpty {
                chip("衝動 \(impulseItemCount)")
                chip("程度 \(entry.impulseSeverities.count)")
            }
            
            if entry.photos.count > 0 {
                chip("照片 \(entry.photos.count)")
            }
        }
        .font(.footnote)
    }
    
    private var impulseItemCount: Int {
        // 把各程度的選項數量加總（去重與否看你想要）
        entry.impulseSeverities.reduce(0) { sum, sev in
            sum + (entry.impulseTypesBySeverity[sev]?.count ?? 0)
        }
    }
    
    @ViewBuilder
    private var observationPreview: some View {
        let text = entry.specialObservation.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(4)
        }
    }
    
    // MARK: helpers
    
    private var wakeText: String {
        switch entry.wakeTime {
        case .unknown:
            return "忘記"
        case .time(let d):
            return timeText(d)
        }
    }
    
    private var bedText: String {
        switch entry.bedTime {
        case .unknown:
            return "忘記"
        case .time(let d):
            return timeText(d)
        }
    }
    
    private func timeText(_ d: Date) -> String {
        d.formatted(date: .omitted, time: .shortened)
    }
    
    private var shortSleepQualityText: String {
        // rawValue 可能很長，先切到括號前
        entry.sleepQuality.rawValue.components(separatedBy: "（").first ?? entry.sleepQuality.rawValue
    }
    
    private func metric(_ title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).foregroundStyle(.secondary)
            Text("\(value)/10").font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func chip(_ text: String) -> some View {
        Text(text)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial)
            .clipShape(Capsule())
    }
}

private extension DailyLogHistoryView {
    var dailyLogActions: [FabAction] {
        [
            FabAction(title: "寫新日記", systemImage: "plus") {
                createNewOrEditToday()
            },
            FabAction(title: "搜尋日記", systemImage: "magnifyingglass") {
                // 預留：搜尋功能
            }
        ]
    }
    
    func createNewOrEditToday() {
        editingEntry = store.addToday()
    }
}
