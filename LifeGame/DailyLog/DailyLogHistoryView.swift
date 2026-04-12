import SwiftUI

struct DailyLogHistoryView: View {

    @ObservedObject var store: DailyLogStore
    @State private var showingAdd = false
    @State private var showingReview = false

    var body: some View {
        List {
            if store.entries.isEmpty {
                ContentUnavailableView("還沒有紀錄",
                                       systemImage: "square.and.pencil",
                                       description: Text("按右下角 ＋ 新增第一篇每日紀錄"))
            } else {
                ForEach(store.entries) { entry in
                    NavigationLink {
                        DailyLogEditorView(mode: .edit(entry), store: store)
                    } label: {
                        DailyLogRow(entry: entry)
                    }
                }
                .onDelete(perform: store.delete)
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
                Text(entry.weather.rawValue)
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
