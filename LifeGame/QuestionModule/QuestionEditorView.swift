import SwiftUI

struct QuestionEditorView: View {
    let question: QuestionDefinition?
    let allQuestions: [QuestionDefinition]
    let onSave: (QuestionDefinition) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var type: QuestionType
    @State private var options: [String]
    @State private var rangeMin: Int
    @State private var rangeMax: Int
    @State private var nestedGroups: [NestedGroup]
    @State private var hasConditionalTrigger: Bool
    @State private var triggerParentId: UUID?
    @State private var triggerValues: String

    private let questionId: UUID

    init(question: QuestionDefinition?, allQuestions: [QuestionDefinition], onSave: @escaping (QuestionDefinition) -> Void) {
        self.question = question
        self.allQuestions = allQuestions
        self.onSave = onSave

        if let q = question {
            _title = State(initialValue: q.title)
            _type = State(initialValue: q.type)
            _options = State(initialValue: q.options ?? [])
            _rangeMin = State(initialValue: q.rangeMin ?? 1)
            _rangeMax = State(initialValue: q.rangeMax ?? 10)
            _nestedGroups = State(initialValue: q.nestedGroups ?? [])
            _hasConditionalTrigger = State(initialValue: q.conditionalTrigger != nil)
            _triggerParentId = State(initialValue: q.conditionalTrigger?.parentQuestionId)
            _triggerValues = State(initialValue: q.conditionalTrigger?.triggerValues.joined(separator: ", ") ?? "")
            questionId = q.id
        } else {
            _title = State(initialValue: "")
            _type = State(initialValue: .freeText)
            _options = State(initialValue: [])
            _rangeMin = State(initialValue: 1)
            _rangeMax = State(initialValue: 10)
            _nestedGroups = State(initialValue: [])
            _hasConditionalTrigger = State(initialValue: false)
            _triggerParentId = State(initialValue: nil)
            _triggerValues = State(initialValue: "")
            questionId = UUID()
        }
    }

    var body: some View {
        Form {
            Section("基本") {
                TextField("問題標題", text: $title)

                Picker("問題類型", selection: $type) {
                    ForEach(QuestionType.allCases) { t in
                        Text(t.displayName).tag(t)
                    }
                }
            }

            // 選項設定（單選/多選）
            if type == .singleSelect || type == .multiSelect {
                optionsSection
            }

            // 範圍設定（滑桿/數字）
            if type == .slider || type == .numberInput {
                rangeSection
            }

            // 巢狀多選分組
            if type == .nestedMultiSelect {
                nestedGroupsSection
            }

            // 條件觸發
            conditionalTriggerSection
        }
        .navigationTitle(question == nil ? "新增問題" : "編輯問題")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if question == nil {
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
    }

    // MARK: - 選項

    private var optionsSection: some View {
        Section("選項") {
            ForEach(options.indices, id: \.self) { index in
                TextField("選項 \(index + 1)", text: $options[index])
            }
            .onDelete { offsets in
                options.remove(atOffsets: offsets)
            }

            Button {
                options.append("")
            } label: {
                Label("新增選項", systemImage: "plus.circle")
            }
        }
    }

    // MARK: - 範圍

    private var rangeSection: some View {
        Section("範圍") {
            Stepper("最小值: \(rangeMin)", value: $rangeMin, in: 0...rangeMax - 1)
            Stepper("最大值: \(rangeMax)", value: $rangeMax, in: rangeMin + 1...100)
        }
    }

    // MARK: - 巢狀分組

    private var nestedGroupsSection: some View {
        Section("巢狀分組") {
            ForEach(nestedGroups.indices, id: \.self) { gIdx in
                VStack(alignment: .leading, spacing: 4) {
                    TextField("分組名稱", text: $nestedGroups[gIdx].label)
                        .font(.headline)

                    ForEach(nestedGroups[gIdx].subOptions.indices, id: \.self) { oIdx in
                        TextField("子選項", text: $nestedGroups[gIdx].subOptions[oIdx])
                            .padding(.leading, 16)
                    }
                    .onDelete { offsets in
                        nestedGroups[gIdx].subOptions.remove(atOffsets: offsets)
                    }

                    Button {
                        nestedGroups[gIdx].subOptions.append("")
                    } label: {
                        Label("新增子選項", systemImage: "plus.circle")
                            .font(.caption)
                    }
                    .padding(.leading, 16)
                }
                .padding(.vertical, 4)
            }
            .onDelete { offsets in
                nestedGroups.remove(atOffsets: offsets)
            }

            Button {
                nestedGroups.append(NestedGroup(label: "", subOptions: []))
            } label: {
                Label("新增分組", systemImage: "plus.circle")
            }
        }
    }

    // MARK: - 條件觸發

    private var conditionalTriggerSection: some View {
        Section {
            Toggle("依前題答案決定是否顯示", isOn: $hasConditionalTrigger)

            if hasConditionalTrigger {
                let otherQuestions = allQuestions.filter { $0.id != questionId }

                if otherQuestions.isEmpty {
                    Text("目前沒有其他問題可以作為條件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Picker("當哪一題", selection: $triggerParentId) {
                        Text("選擇問題").tag(nil as UUID?)
                        ForEach(otherQuestions) { q in
                            Text(q.title).tag(q.id as UUID?)
                        }
                    }

                    if let parentId = triggerParentId,
                       let parent = allQuestions.first(where: { $0.id == parentId }),
                       let parentOptions = parent.options, !parentOptions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("答案是以下選項時才顯示：")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(parentOptions, id: \.self) { option in
                                let selected = triggerValues.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                                Button {
                                    toggleTriggerValue(option)
                                } label: {
                                    HStack {
                                        Image(systemName: selected.contains(option) ? "checkmark.square.fill" : "square")
                                            .foregroundStyle(selected.contains(option) ? .blue : .secondary)
                                        Text(option)
                                            .foregroundStyle(.primary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else if triggerParentId != nil {
                        TextField("答案包含（逗號分隔）", text: $triggerValues)
                    }
                }
            }
        } header: {
            Text("條件顯示")
        } footer: {
            Text("開啟後，此問題只會在前一題選了指定答案時才出現")
        }
    }

    private func toggleTriggerValue(_ value: String) {
        var values = triggerValues.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if values.contains(value) {
            values.removeAll { $0 == value }
        } else {
            values.append(value)
        }
        triggerValues = values.joined(separator: ", ")
    }

    // MARK: - Save

    private func save() {
        let filteredOptions = options.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let filteredGroups = nestedGroups.filter { !$0.label.trimmingCharacters(in: .whitespaces).isEmpty }

        var trigger: ConditionalTrigger? = nil
        if hasConditionalTrigger, let parentId = triggerParentId {
            let values = triggerValues
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            trigger = ConditionalTrigger(parentQuestionId: parentId, triggerValues: values)
        }

        let q = QuestionDefinition(
            id: questionId,
            type: type,
            title: title,
            options: filteredOptions.isEmpty ? nil : filteredOptions,
            rangeMin: (type == .slider || type == .numberInput) ? rangeMin : nil,
            rangeMax: (type == .slider || type == .numberInput) ? rangeMax : nil,
            conditionalTrigger: trigger,
            subQuestions: nil,
            nestedGroups: filteredGroups.isEmpty ? nil : filteredGroups
        )

        onSave(q)
    }
}
