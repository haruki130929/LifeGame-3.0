import SwiftUI

/// 編輯單一欄位定義：包裝 QuestionEditorView + 圖表類型選擇
struct PracticeFieldEditorView: View {
    let field: PracticeFieldDefinition?
    let allFields: [PracticeFieldDefinition]
    let onSave: (PracticeFieldDefinition) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var question: QuestionDefinition
    @State private var chartType: ChartType?
    @State private var questionSaved = false

    private let fieldId: UUID

    init(field: PracticeFieldDefinition?, allFields: [PracticeFieldDefinition], onSave: @escaping (PracticeFieldDefinition) -> Void) {
        self.field = field
        self.allFields = allFields
        self.onSave = onSave

        if let f = field {
            _question = State(initialValue: f.question)
            _chartType = State(initialValue: f.chartType)
            fieldId = f.id
        } else {
            _question = State(initialValue: QuestionDefinition(type: .freeText, title: ""))
            _chartType = State(initialValue: nil)
            fieldId = UUID()
        }
    }

    var body: some View {
        Form {
            // 直接複用 QuestionEditorView 的內容，但嵌入在這裡
            questionEditorSection

            Section("圖表設定") {
                Picker("圖表類型", selection: $chartType) {
                    Text("自動").tag(nil as ChartType?)
                    ForEach(ChartType.allCases) { type in
                        Label(type.displayName, systemImage: type.systemImage)
                            .tag(type as ChartType?)
                    }
                }

                if let effective = effectiveChartType {
                    HStack {
                        Text("將使用")
                            .foregroundStyle(.secondary)
                        Label(effective.displayName, systemImage: effective.systemImage)
                            .foregroundStyle(.blue)
                    }
                    .font(.caption)
                } else {
                    Text("此欄位類型不支援圖表")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(field == nil ? "新增欄位" : "編輯欄位")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if field == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") {
                    save()
                    dismiss()
                }
                .disabled(question.title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var effectiveChartType: ChartType? {
        let field = PracticeFieldDefinition(id: fieldId, question: question, chartType: chartType)
        return field.effectiveChartType
    }

    // MARK: - Question Editor（內嵌版）

    @State private var options: [String] = []
    @State private var rangeMin: Int = 1
    @State private var rangeMax: Int = 10
    @State private var nestedGroups: [NestedGroup] = []

    private var questionEditorSection: some View {
        Group {
            Section("基本") {
                TextField("欄位標題", text: $question.title)

                Picker("欄位類型", selection: $question.type) {
                    ForEach(QuestionType.allCases) { t in
                        Text(t.displayName).tag(t)
                    }
                }
            }

            if question.type == .singleSelect || question.type == .multiSelect {
                Section("選項") {
                    ForEach(Array((question.options ?? []).enumerated()), id: \.offset) { index, _ in
                        TextField("選項 \(index + 1)", text: optionBinding(at: index))
                    }
                    .onDelete { offsets in
                        var opts = question.options ?? []
                        opts.remove(atOffsets: offsets)
                        question.options = opts
                    }

                    Button {
                        var opts = question.options ?? []
                        opts.append("")
                        question.options = opts
                    } label: {
                        Label("新增選項", systemImage: "plus.circle")
                    }
                }
            }

            if question.type == .slider || question.type == .numberInput {
                Section("範圍") {
                    Stepper("最小值: \(question.rangeMin ?? 1)", value: rangeMinBinding, in: 0...(question.rangeMax ?? 10) - 1)
                    Stepper("最大值: \(question.rangeMax ?? 10)", value: rangeMaxBinding, in: (question.rangeMin ?? 1) + 1...100)
                }
            }

            if question.type == .nestedMultiSelect {
                nestedGroupsSection
            }
        }
    }

    private func optionBinding(at index: Int) -> Binding<String> {
        Binding(
            get: { question.options?[safe: index] ?? "" },
            set: { newValue in
                var opts = question.options ?? []
                if index < opts.count {
                    opts[index] = newValue
                }
                question.options = opts
            }
        )
    }

    private var rangeMinBinding: Binding<Int> {
        Binding(
            get: { question.rangeMin ?? 1 },
            set: { question.rangeMin = $0 }
        )
    }

    private var rangeMaxBinding: Binding<Int> {
        Binding(
            get: { question.rangeMax ?? 10 },
            set: { question.rangeMax = $0 }
        )
    }

    private var nestedGroupsSection: some View {
        Section("巢狀分組") {
            ForEach(Array((question.nestedGroups ?? []).enumerated()), id: \.offset) { gIdx, _ in
                VStack(alignment: .leading, spacing: 4) {
                    TextField("分組名稱", text: nestedGroupLabelBinding(at: gIdx))
                        .font(.headline)

                    let subOptions = question.nestedGroups?[safe: gIdx]?.subOptions ?? []
                    ForEach(Array(subOptions.enumerated()), id: \.offset) { oIdx, _ in
                        TextField("子選項", text: nestedSubOptionBinding(groupIndex: gIdx, optionIndex: oIdx))
                            .padding(.leading, 16)
                    }

                    Button {
                        var groups = question.nestedGroups ?? []
                        if gIdx < groups.count {
                            groups[gIdx].subOptions.append("")
                            question.nestedGroups = groups
                        }
                    } label: {
                        Label("新增子選項", systemImage: "plus.circle")
                            .font(.caption)
                    }
                    .padding(.leading, 16)
                }
                .padding(.vertical, 4)
            }
            .onDelete { offsets in
                var groups = question.nestedGroups ?? []
                groups.remove(atOffsets: offsets)
                question.nestedGroups = groups
            }

            Button {
                var groups = question.nestedGroups ?? []
                groups.append(NestedGroup(label: "", subOptions: []))
                question.nestedGroups = groups
            } label: {
                Label("新增分組", systemImage: "plus.circle")
            }
        }
    }

    private func nestedGroupLabelBinding(at index: Int) -> Binding<String> {
        Binding(
            get: { question.nestedGroups?[safe: index]?.label ?? "" },
            set: {
                var groups = question.nestedGroups ?? []
                if index < groups.count {
                    groups[index].label = $0
                    question.nestedGroups = groups
                }
            }
        )
    }

    private func nestedSubOptionBinding(groupIndex: Int, optionIndex: Int) -> Binding<String> {
        Binding(
            get: { question.nestedGroups?[safe: groupIndex]?.subOptions[safe: optionIndex] ?? "" },
            set: {
                var groups = question.nestedGroups ?? []
                if groupIndex < groups.count, optionIndex < groups[groupIndex].subOptions.count {
                    groups[groupIndex].subOptions[optionIndex] = $0
                    question.nestedGroups = groups
                }
            }
        )
    }

    // MARK: - Save

    private func save() {
        // 清理空選項
        if let opts = question.options {
            question.options = opts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            if question.options?.isEmpty == true { question.options = nil }
        }
        if let groups = question.nestedGroups {
            question.nestedGroups = groups.filter { !$0.label.trimmingCharacters(in: .whitespaces).isEmpty }
            if question.nestedGroups?.isEmpty == true { question.nestedGroups = nil }
        }

        // 只在相關類型保留範圍
        if question.type != .slider && question.type != .numberInput {
            question.rangeMin = nil
            question.rangeMax = nil
        }

        let result = PracticeFieldDefinition(
            id: fieldId,
            question: question,
            chartType: chartType
        )
        onSave(result)
    }
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
