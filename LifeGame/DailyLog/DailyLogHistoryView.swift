import SwiftUI

struct DailyLogHistoryView: View {

    @ObservedObject var store: DailyLogStore
    @State private var showingAdd = false
    @State private var showingReview = false
    @State private var chartRange: ChartRange = .twoWeeks
    @State private var collapsedMonths: Set<String> = []
    @State private var cachedGroups: [MonthGroup] = []
    @State private var lastEntryCount: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // 圖表區（至少 2 筆紀錄才顯示）
            if store.entries.count >= 2 {
                DailyLogChartsSection(entries: store.entries, selectedRange: $chartRange)
            }

            List {
                if store.entries.isEmpty {
                    ContentUnavailableView("還沒有紀錄",
                                           systemImage: "square.and.pencil",
                                           description: Text("按右下角 ＋ 新增第一篇每日紀錄"))
                } else {
                    ForEach(cachedGroups) { group in
                        Section {
                            if !collapsedMonths.contains(group.key) {
                                ForEach(group.entries) { entry in
                                    NavigationLink {
                                        DailyLogEditorView(mode: .edit(entry), store: store)
                                    } label: {
                                        DailyLogRow(entry: entry)
                                    }
                                }
                                .onDelete { offsets in
                                    deleteEntries(offsets, in: group.entries)
                                }
                            }
                        } header: {
                            Button {
                                withAnimation {
                                    if collapsedMonths.contains(group.key) {
                                        collapsedMonths.remove(group.key)
                                    } else {
                                        collapsedMonths.insert(group.key)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(group.key)
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(group.entries.count) 筆")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Image(systemName: collapsedMonths.contains(group.key) ? "chevron.right" : "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationTitle("每日紀錄")
        .fabMenu([
            FabAction(title: "寫新日記", systemImage: "plus") {
                showingAdd = true
            },
            FabAction(title: "檢視紀錄", systemImage: "doc.text.magnifyingglass") {
                showingReview = true
            },
            FabAction(title: "設定", systemImage: "gearshape", route: .featureSettings(.dailyLog)) { }
        ])
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                DailyLogEditorView(mode: .add, store: store)
            }
        }
        .sheet(isPresented: $showingReview) {
            DailyLogReviewRangeSheet(allEntries: store.entries)
        }
        .featureTutorial(.dailyLog)
        .onAppear { rebuildGroupsIfNeeded() }
        .onChange(of: store.entries.count) { _, _ in rebuildGroupsIfNeeded() }
    }

    private func rebuildGroupsIfNeeded() {
        guard store.entries.count != lastEntryCount else { return }
        lastEntryCount = store.entries.count

        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "zh_TW")
        fmt.dateFormat = "yyyy年M月"

        let grouped = Dictionary(grouping: store.entries) { entry in
            fmt.string(from: entry.date)
        }

        cachedGroups = grouped
            .map { MonthGroup(key: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { a, b in
                guard let da = a.entries.first?.date, let db = b.entries.first?.date else { return false }
                return da > db
            }
    }

    private func deleteEntries(_ offsets: IndexSet, in groupEntries: [DailyLogEntry]) {
        let idsToDelete = offsets.map { groupEntries[$0].id }
        for id in idsToDelete {
            if let globalIndex = store.entries.firstIndex(where: { $0.id == id }) {
                store.delete(at: IndexSet(integer: globalIndex))
            }
        }
    }
}

// MARK: - 列表列（簡潔風格，像弓道筆記）

private struct DailyLogRow: View {
    let entry: DailyLogEntry
    @EnvironmentObject private var moduleStore: QuestionModuleStore

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 日期 + 天氣
            HStack {
                Text(entry.date, format: .dateTime.year().month().day())
                    .font(.headline)
                Spacer()
                Text(displayWeather)
                    .foregroundStyle(.secondary)
            }

            // 分數摘要 — 依模組是否自訂來決定顯示方式
            if let summaryText = buildSummary() {
                Text(summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // 觀察預覽（如有）
            let obs = entry.specialObservation.trimmingCharacters(in: .whitespacesAndNewlines)
            if !obs.isEmpty {
                Text(obs)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    /// 天氣：優先從 customAnswers 取（自訂模組），沒有才用原生欄位
    private var displayWeather: String {
        if let basicModule = moduleStore.modules.first(where: { $0.kind == .basic }),
           let questions = basicModule.questions,
           let weatherQ = questions.first(where: { $0.title == "天氣" }),
           let answer = entry.customAnswers.first(where: { $0.questionId == weatherQ.id }),
           let value = answer.stringValue, !value.isEmpty {
            return value
        }
        return entry.weather.rawValue
    }

    /// 建立摘要文字：從 dedicated fields 或 customAnswers 取值
    private func buildSummary() -> String? {
        var parts: [String] = []

        // 情緒分數（moodMental 模組）
        if let module = moduleStore.modules.first(where: { $0.kind == .moodMental }),
           let questions = module.questions, !questions.isEmpty {
            // 自訂模組 → 從 customAnswers 取前兩個 slider/number 值
            for q in questions where q.type == .slider || q.type == .numberInput {
                if let a = entry.customAnswers.first(where: { $0.questionId == q.id }),
                   let v = a.intValue {
                    parts.append("\(q.title) \(v)")
                }
                if parts.count >= 2 { break }
            }
        } else {
            // 未自訂 → 用 dedicated fields
            parts.append("情緒 \(entry.overallMoodScore)")
            parts.append("焦慮 \(entry.anxietyScore)")
        }

        // 疲勞分數（body 模組）
        if let module = moduleStore.modules.first(where: { $0.kind == .body }),
           let questions = module.questions, !questions.isEmpty {
            for q in questions where q.type == .slider || q.type == .numberInput {
                if let a = entry.customAnswers.first(where: { $0.questionId == q.id }),
                   let v = a.intValue {
                    parts.append("\(q.title) \(v)")
                    break
                }
            }
        } else {
            parts.append("疲勞 \(entry.fatigueScore)")
        }

        return parts.isEmpty ? nil : parts.joined(separator: "｜")
    }
}

// MARK: - Month Group

private struct MonthGroup: Identifiable {
    let key: String
    let entries: [DailyLogEntry]
    var id: String { key }
}
