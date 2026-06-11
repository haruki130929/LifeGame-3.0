import SwiftUI

struct DailyLogHistoryView: View {

    @ObservedObject var store: DailyLogStore
    @EnvironmentObject private var fab: FabStore
    @State private var activeSheet: ActiveSheet?
    @State private var chartRange: ChartRange = .twoWeeks
    @State private var collapsedMonths: Set<String> = []
    @State private var cachedGroups: [MonthGroup] = []
    @State private var lastEntryCount: Int = 0

    /// 統一用單一 sheet（避免多個 .sheet 疊在同一 view 互相閃爍）
    private enum ActiveSheet: Int, Identifiable {
        case add, review, export
        var id: Int { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 圖表區
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
        .onAppear {
            fab.apply(context: .feature(.dailyLog))
            rebuildGroupsIfNeeded()
        }
        .onDisappear { fab.popActions() }
        .onChange(of: store.entries.count) { _, _ in rebuildGroupsIfNeeded() }
        .onChange(of: fab.route) { _, newRoute in
            switch newRoute {
            case .addDailyLog:
                fab.route = nil
                activeSheet = .add
            case .reviewDailyLog:
                fab.route = nil
                activeSheet = .review
            case .exportDailyLog:
                fab.route = nil
                activeSheet = .export
            default:
                break
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .add:
                NavigationStack {
                    DailyLogEditorView(mode: .add, store: store)
                }
            case .review:
                DailyLogReviewRangeSheet(allEntries: store.entries)
            case .export:
                DailyLogExportSheet(allEntries: store.entries)
            }
        }
        .featureTutorial(.dailyLog)
    }

    // MARK: - Helpers

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

// MARK: - 列表列

private struct DailyLogRow: View {
    let entry: DailyLogEntry
    @EnvironmentObject private var moduleStore: QuestionModuleStore

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.date, format: .dateTime.year().month().day())
                    .font(.headline)
                Spacer()
                Text(displayWeather)
                    .foregroundStyle(.secondary)
            }

            if let summaryText = buildSummary() {
                Text(summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

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

    private func buildSummary() -> String? {
        var parts: [String] = []

        if let module = moduleStore.modules.first(where: { $0.kind == .moodMental }),
           let questions = module.questions, !questions.isEmpty {
            for q in questions where q.type == .slider || q.type == .numberInput {
                if let a = entry.customAnswers.first(where: { $0.questionId == q.id }),
                   let v = a.intValue {
                    parts.append("\(q.title) \(v)")
                }
                if parts.count >= 2 { break }
            }
        } else {
            parts.append("情緒 \(entry.overallMoodScore)")
            parts.append("焦慮 \(entry.anxietyScore)")
        }

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
