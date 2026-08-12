import SwiftUI

/// 顯示單本練習日記的所有紀錄
struct PracticeEntryListView: View {
    let diary: PracticeDiary
    @ObservedObject var store: PracticeDiaryStore

    @State private var showingAddEntry = false

    private var entries: [PracticeEntry] {
        store.entries(for: diary.id)
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "還沒有紀錄",
                    systemImage: "note.text",
                    description: Text("點擊下方按鈕開始記錄練習")
                )
            } else {
                List {
                    ForEach(entries) { entry in
                        NavigationLink {
                            PracticeEntryEditorView(
                                mode: .edit(entry),
                                diary: diary,
                                store: store
                            )
                            .hidesFab()
                        } label: {
                            entryRow(entry)
                        }
                    }
                    .onDelete { offsets in
                        store.deleteEntries(for: diary.id, at: offsets)
                    }
                }
            }
        }
        .navigationTitle(diary.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    NavigationLink {
                        PracticeChartView(diary: diary, store: store)
                            .hidesFab()
                    } label: {
                        Image(systemName: "chart.bar.xaxis")
                    }

                    Button {
                        showingAddEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            NavigationStack {
                PracticeEntryEditorView(
                    mode: .add,
                    diary: diary,
                    store: store
                )
            }
        }
    }

    // MARK: - Row

    private func entryRow(_ entry: PracticeEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.date, format: .dateTime.year().month().day())
                .font(.headline)

            // 顯示前兩個有值的欄位摘要
            let summaries = fieldSummaries(for: entry)
            if !summaries.isEmpty {
                Text(summaries.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private func fieldSummaries(for entry: PracticeEntry) -> [String] {
        var result: [String] = []
        for field in diary.fields.prefix(3) {
            guard let answer = entry.answers.first(where: { $0.questionId == field.question.id }) else { continue }
            if let intVal = answer.intValue {
                result.append("\(field.question.title): \(intVal)")
            } else if let strVal = answer.stringValue, !strVal.isEmpty {
                let preview = strVal.prefix(15)
                result.append("\(field.question.title): \(preview)")
            } else if let arr = answer.stringArrayValue, !arr.isEmpty {
                result.append(String(localized: "\(field.question.title): \(arr.count) 項"))
            }
            if result.count >= 2 { break }
        }
        return result
    }
}
