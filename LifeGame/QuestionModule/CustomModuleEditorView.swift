import SwiftUI

struct CustomModuleEditorView: View {
    enum Mode {
        case create
        case edit(DailyLogModule)
    }

    let mode: Mode
    let onSave: (DailyLogModule) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var icon: String
    @State private var questions: [QuestionDefinition]
    @State private var showingQuestionEditor = false

    private let moduleId: UUID

    init(mode: Mode, onSave: @escaping (DailyLogModule) -> Void) {
        self.mode = mode
        self.onSave = onSave

        switch mode {
        case .create:
            _title = State(initialValue: "")
            _icon = State(initialValue: "square.grid.2x2")
            _questions = State(initialValue: [])
            moduleId = UUID()
        case .edit(let module):
            _title = State(initialValue: module.title ?? "")
            _icon = State(initialValue: module.icon ?? "square.grid.2x2")
            _questions = State(initialValue: module.questions ?? [])
            moduleId = module.id
        }
    }

    var body: some View {
        Form {
            Section("模組資訊") {
                TextField("模組名稱", text: $title)

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
                ForEach(questions) { question in
                    NavigationLink {
                        QuestionEditorView(
                            question: question,
                            allQuestions: questions
                        ) { updated in
                            if let idx = questions.firstIndex(where: { $0.id == updated.id }) {
                                questions[idx] = updated
                            }
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(question.title)
                            Text(question.type.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    questions.remove(atOffsets: offsets)
                }
                .onMove { from, to in
                    questions.move(fromOffsets: from, toOffset: to)
                }

                Button {
                    showingQuestionEditor = true
                } label: {
                    Label("新增問題", systemImage: "plus.circle")
                }
            } header: {
                Text("問題列表")
            }
        }
        .navigationTitle(isCreating ? "新增自訂模組" : "編輯模組")
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
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .sheet(isPresented: $showingQuestionEditor) {
            NavigationStack {
                QuestionEditorView(
                    question: nil,
                    allQuestions: questions
                ) { newQuestion in
                    questions.append(newQuestion)
                }
            }
        }
    }

    private var isCreating: Bool {
        if case .create = mode { return true }
        return false
    }

    private func save() {
        var module: DailyLogModule
        switch mode {
        case .create:
            module = DailyLogModule(
                id: moduleId,
                kind: .custom,
                isEnabled: true,
                sortOrder: 0,
                title: title,
                icon: icon,
                questions: questions
            )
        case .edit(let existing):
            module = existing
            module.title = title
            module.icon = icon
            module.questions = questions
        }
        onSave(module)
    }
}
