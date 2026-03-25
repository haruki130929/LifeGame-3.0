import SwiftUI

/// 新增或編輯一筆練習紀錄
struct PracticeEntryEditorView: View {
    enum Mode {
        case add
        case edit(PracticeEntry)
    }

    let mode: Mode
    let diary: PracticeDiary
    @ObservedObject var store: PracticeDiaryStore

    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var answers: [CustomAnswer]

    private let entryId: UUID

    init(mode: Mode, diary: PracticeDiary, store: PracticeDiaryStore) {
        self.mode = mode
        self.diary = diary
        self.store = store

        switch mode {
        case .add:
            _date = State(initialValue: Date())
            _answers = State(initialValue: [])
            entryId = UUID()
        case .edit(let entry):
            _date = State(initialValue: entry.date)
            _answers = State(initialValue: entry.answers)
            entryId = entry.id
        }
    }

    var body: some View {
        Form {
            Section("日期") {
                DatePicker("練習日期", selection: $date, displayedComponents: .date)
            }

            ForEach(diary.fields) { field in
                Section(field.question.title) {
                    QuestionFieldView(
                        question: field.question,
                        answers: $answers
                    )
                }
            }
        }
        .navigationTitle(isAdding ? "新增紀錄" : "編輯紀錄")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isAdding {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") {
                    save()
                    dismiss()
                }
            }
        }
    }

    private var isAdding: Bool {
        if case .add = mode { return true }
        return false
    }

    private func save() {
        let entry = PracticeEntry(
            id: entryId,
            diaryId: diary.id,
            date: date,
            answers: answers
        )

        switch mode {
        case .add:
            store.addEntry(entry)
        case .edit:
            store.updateEntry(entry)
        }
    }
}
