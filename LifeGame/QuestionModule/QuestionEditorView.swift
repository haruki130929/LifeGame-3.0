import SwiftUI

struct QuestionEditorView: View {
    let question: QuestionDefinition?
    let allQuestions: [QuestionDefinition]
    let onSave: (QuestionDefinition) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var fab: FabStore

    @State private var title: String
    @State private var type: QuestionType
    @State private var options: [String]
    @State private var rangeMin: Int
    @State private var rangeMax: Int
    @State private var nestedGroups: [NestedGroup]
    @State private var hasConditionalTrigger: Bool
    @State private var triggerParentId: UUID?
    @State private var triggerValues: String
    @State private var customTriggerInput: String = ""
    @State private var triggerOptions: [String] = []  // 可編輯的觸發選項列表

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
            // 初始化可編輯的觸發選項
            if q.conditionalTrigger != nil {
                var opts = allQuestions.filter { $0.id != q.id }.flatMap { $0.options ?? [] }
                let existing = q.conditionalTrigger?.triggerValues ?? []
                for v in existing where !opts.contains(v) {
                    opts.append(v)
                }
                _triggerOptions = State(initialValue: opts)
            }
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
        .onAppear { fab.isHidden = true }
        .onDisappear { fab.isHidden = false }
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

    /// 收集其他問題裡所有的選項，以 (問題標題, 選項, 問題ID) 分組
    private var allAvailableOptions: [(questionTitle: String, questionId: UUID, option: String)] {
        allQuestions
            .filter { $0.id != questionId }
            .flatMap { q in
                (q.options ?? []).map { (q.title, q.id, $0) }
            }
    }

    private var conditionalTriggerSection: some View {
        Section {
            Toggle("依選項決定是否顯示", isOn: $hasConditionalTrigger)
                .onChange(of: hasConditionalTrigger) { _, on in
                    if on && triggerOptions.isEmpty {
                        // 從其他問題收集所有選項作為預設
                        triggerOptions = allQuestions
                            .filter { $0.id != questionId }
                            .flatMap { $0.options ?? [] }
                        // 加入已有的自訂觸發值
                        let existing = triggerValues.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                        for v in existing where !triggerOptions.contains(v) {
                            triggerOptions.append(v)
                        }
                    }
                }

            if hasConditionalTrigger {
                // 可編輯的選項列表
                ForEach(triggerOptions.indices, id: \.self) { idx in
                    let selected = triggerValues.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    let isChecked = selected.contains(triggerOptions[idx])

                    HStack {
                        Button {
                            toggleTriggerValue(triggerOptions[idx])
                        } label: {
                            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                                .foregroundStyle(isChecked ? .blue : .secondary)
                        }
                        .buttonStyle(.plain)

                        TextField("選項", text: $triggerOptions[idx])
                            .onChange(of: triggerOptions[idx]) { oldVal, newVal in
                                // 如果這個選項被勾選了，同步更新 triggerValues
                                var values = triggerValues.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                                if let i = values.firstIndex(of: oldVal) {
                                    values[i] = newVal
                                    triggerValues = values.joined(separator: ", ")
                                }
                            }

                        Button {
                            // 先取消勾選
                            var values = triggerValues.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                            values.removeAll { $0 == triggerOptions[idx] }
                            triggerValues = values.joined(separator: ", ")
                            triggerOptions.remove(at: idx)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // 新增選項
                HStack {
                    TextField("新增條件選項", text: $customTriggerInput)
                    Button {
                        let value = customTriggerInput.trimmingCharacters(in: .whitespaces)
                        guard !value.isEmpty else { return }
                        triggerOptions.append(value)
                        customTriggerInput = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(customTriggerInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        } header: {
            Text("條件顯示")
        } footer: {
            Text("勾選選項後，此問題只會在使用者選了該選項時才出現。可編輯或新增選項。")
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
        if hasConditionalTrigger {
            let values = triggerValues
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            if !values.isEmpty {
                // 嘗試找到包含被勾選選項的父問題
                let parentId = triggerParentId ?? allQuestions.first(where: { q in
                    q.id != questionId && (q.options ?? []).contains(where: { values.contains($0) })
                })?.id ?? questionId
                trigger = ConditionalTrigger(parentQuestionId: parentId, triggerValues: values)
            }
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
