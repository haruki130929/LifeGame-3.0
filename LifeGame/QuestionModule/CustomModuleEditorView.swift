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
            }

            Section("圖示") {
                iconPicker
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

    // MARK: - 圖示選擇器

    private static let iconOptions: [(String, [String])] = [
        ("常用", ["square.grid.2x2", "list.bullet", "checklist", "doc.text", "note.text", "pencil.and.list.clipboard", "clipboard", "chart.bar", "chart.pie", "chart.line.uptrend.xyaxis"]),
        ("心理", ["brain.head.profile", "heart", "heart.text.square", "face.smiling", "sun.max", "moon.stars", "cloud.rain", "bolt.heart", "waveform.path.ecg", "eye"]),
        ("學習", ["book", "graduationcap", "pencil", "ruler", "lightbulb", "theatermasks", "music.note", "paintbrush", "globe", "questionmark.circle"]),
        ("生活", ["fork.knife", "cup.and.saucer", "bed.double", "figure.walk", "figure.run", "dumbbell", "bicycle", "leaf", "pills", "cross.case"]),
        ("其他", ["star", "flag", "bell", "tag", "bookmark", "calendar", "clock", "timer", "gamecontroller", "camera"]),
    ]

    private var iconPicker: some View {
        let gridItems = Array(repeating: GridItem(.fixed(36), spacing: 8), count: 8)

        return VStack(alignment: .leading, spacing: 12) {
            ForEach(Self.iconOptions, id: \.0) { category, icons in
                VStack(alignment: .leading, spacing: 4) {
                    Text(category)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: gridItems, spacing: 8) {
                        ForEach(icons, id: \.self) { name in
                            Button {
                                icon = name
                            } label: {
                                Image(systemName: name)
                                    .font(.system(size: 18))
                                    .frame(width: 36, height: 36)
                                    .background(icon == name ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(icon == name ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                    )
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(icon == name ? .blue : .primary)
                        }
                    }
                }
            }
        }
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
