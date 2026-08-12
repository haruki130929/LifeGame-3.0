import SwiftUI

/// 建立或編輯一本練習日記的設定（名稱、圖示、欄位）
struct PracticeDiaryConfigView: View {
    enum Mode {
        case create
        case edit(PracticeDiary)
    }

    let mode: Mode
    let onSave: (PracticeDiary) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var icon: String
    @State private var fields: [PracticeFieldDefinition]
    @State private var showingFieldEditor = false

    private let diaryId: UUID
    private let createdAt: Date

    init(mode: Mode, onSave: @escaping (PracticeDiary) -> Void) {
        self.mode = mode
        self.onSave = onSave

        switch mode {
        case .create:
            _name = State(initialValue: "")
            _icon = State(initialValue: "book.closed")
            _fields = State(initialValue: [])
            diaryId = UUID()
            createdAt = Date()
        case .edit(let diary):
            _name = State(initialValue: diary.name)
            _icon = State(initialValue: diary.icon)
            _fields = State(initialValue: diary.fields)
            diaryId = diary.id
            createdAt = diary.createdAt
        }
    }

    var body: some View {
        Form {
            Section("日記資訊") {
                TextField("日記名稱", text: $name)

                HStack {
                    Text("圖示")
                    Spacer()
                    Image(systemName: icon)
                        .foregroundStyle(.blue)
                    TextField("SF Symbol 名稱", text: $icon)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 180)
                }
            }

            Section {
                ForEach(fields) { field in
                    NavigationLink {
                        PracticeFieldEditorView(
                            field: field,
                            allFields: fields
                        ) { updated in
                            if let idx = fields.firstIndex(where: { $0.id == updated.id }) {
                                fields[idx] = updated
                            }
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(field.question.title.isEmpty ? String(localized: "（未命名）") : field.question.title)
                                HStack(spacing: 4) {
                                    Text(field.question.type.displayName)
                                    if let chart = field.effectiveChartType {
                                        Text("·")
                                        Label(chart.displayName, systemImage: chart.systemImage)
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    fields.remove(atOffsets: offsets)
                }
                .onMove { from, to in
                    fields.move(fromOffsets: from, toOffset: to)
                }

                Button {
                    showingFieldEditor = true
                } label: {
                    Label("新增欄位", systemImage: "plus.circle")
                }
            } header: {
                Text("欄位列表")
            }
        }
        .navigationTitle(isCreating ? "新增練習日記" : "編輯日記")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isCreating {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") {
                    save()
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .sheet(isPresented: $showingFieldEditor) {
            NavigationStack {
                PracticeFieldEditorView(
                    field: nil,
                    allFields: fields
                ) { newField in
                    fields.append(newField)
                }
            }
        }
    }

    private var isCreating: Bool {
        if case .create = mode { return true }
        return false
    }

    private func save() {
        let diary = PracticeDiary(
            id: diaryId,
            name: name.trimmingCharacters(in: .whitespaces),
            icon: icon,
            fields: fields,
            createdAt: createdAt
        )
        onSave(diary)
    }
}
