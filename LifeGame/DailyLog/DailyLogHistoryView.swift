import SwiftUI

struct DailyLogHistoryView: View {

    @ObservedObject var store: DailyLogStore
    @State private var showingAdd = false

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
            FabAction(title: "設定", systemImage: "gearshape", route: .featureSettings(.dailyLog)) { }
        ])
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                DailyLogEditorView(mode: .add, store: store)
            }
        }
        .featureTutorial(.dailyLog)
    }
}

// MARK: - 列表列（簡潔風格，像弓道筆記）

private struct DailyLogRow: View {
    let entry: DailyLogEntry

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

            // 分數摘要
            Text("情緒 \(entry.overallMoodScore)｜焦慮 \(entry.anxietyScore)｜疲勞 \(entry.fatigueScore)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

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
}
