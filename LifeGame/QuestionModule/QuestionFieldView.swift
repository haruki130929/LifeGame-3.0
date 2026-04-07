import SwiftUI

/// 根據 QuestionDefinition 的類型渲染對應的表單元件
struct QuestionFieldView: View {
    let question: QuestionDefinition
    @Binding var answers: [CustomAnswer]

    var body: some View {
        switch question.type {
        case .slider:
            sliderField
        case .singleSelect:
            singleSelectField
        case .multiSelect:
            multiSelectField
        case .freeText:
            freeTextField
        case .timePicker:
            timePickerField
        case .numberInput:
            numberInputField
        case .photo:
            photoField
        case .nestedMultiSelect:
            nestedMultiSelectField
        }
    }

    // MARK: - Slider (1-10)

    private var sliderField: some View {
        ScoreSliderRow(
            title: question.title,
            value: Binding(
                get: { answer?.intValue ?? (question.rangeMin ?? 5) },
                set: { upsertAnswer { $0.intValue = $1 }($0) }
            )
        )
    }

    // MARK: - Single Select

    private var singleSelectField: some View {
        let options = (question.options ?? []).map { DynamicOption(rawValue: $0) }
        return VStack(alignment: .leading, spacing: 4) {
            CheckboxSingleSelectList(
                title: question.title,
                options: options,
                selection: Binding(
                    get: {
                        let val = answer?.stringValue ?? ""
                        return DynamicOption(rawValue: val)
                    },
                    set: { upsertAnswer { $0.stringValue = $1.rawValue }($0) }
                )
            )
            if answer?.stringValue == "其他" {
                TextField("其他（請填寫）", text: Binding(
                    get: { answer?.otherText ?? "" },
                    set: { upsertAnswer { $0.otherText = $1 }($0) }
                ))
                .textFieldStyle(.roundedBorder)
            }
        }
    }

    // MARK: - Multi Select

    private var multiSelectField: some View {
        let options = (question.options ?? []).map { DynamicOption(rawValue: $0) }
        return VStack(alignment: .leading, spacing: 4) {
            CheckboxMultiSelectList(
                title: question.title,
                options: options,
                selected: Binding(
                    get: {
                        let vals = answer?.stringArrayValue ?? []
                        return Set(vals.map { DynamicOption(rawValue: $0) })
                    },
                    set: { newSet in
                        var a = answer ?? CustomAnswer(questionId: question.id)
                        a.stringArrayValue = Array(newSet.map(\.rawValue))
                        upsertInPlace(a)
                    }
                )
            )
            if answer?.stringArrayValue?.contains("其他") == true {
                TextField("其他（請填寫）", text: Binding(
                    get: { answer?.otherText ?? "" },
                    set: { upsertAnswer { $0.otherText = $1 }($0) }
                ))
                .textFieldStyle(.roundedBorder)
            }
        }
    }

    // MARK: - Free Text

    private var freeTextField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(question.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextEditor(text: Binding(
                get: { answer?.stringValue ?? "" },
                set: { upsertAnswer { $0.stringValue = $1 }($0) }
            ))
            .frame(minHeight: 80)
        }
    }

    // MARK: - Time Picker

    private var timePickerField: some View {
        HalfHourOptionalTimePickerRow(
            title: question.title,
            value: Binding(
                get: {
                    if let date = answer?.dateValue {
                        return .time(date)
                    }
                    return .unknown
                },
                set: { newVal in
                    var a = answer ?? CustomAnswer(questionId: question.id)
                    a.dateValue = newVal.dateValue
                    upsertInPlace(a)
                }
            )
        )
    }

    // MARK: - Number Input

    private var numberInputField: some View {
        HStack {
            Text(question.title)
            Spacer()
            TextField(
                "數字",
                value: Binding(
                    get: { answer?.intValue ?? 0 },
                    set: { upsertAnswer { $0.intValue = $1 }($0) }
                ),
                format: .number
            )
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 80)
        }
    }

    // MARK: - Photo

    private var photoField: some View {
        // 簡化版：顯示標題，之後可以擴充成完整的照片選擇器
        VStack(alignment: .leading, spacing: 4) {
            Text(question.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("照片功能（開發中）")
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Nested Multi Select

    private var nestedMultiSelectField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(question.nestedGroups ?? []) { group in
                let groupOptions = group.subOptions.map { DynamicOption(rawValue: $0) }

                CheckboxMultiSelectList(
                    title: group.label,
                    options: groupOptions,
                    selected: Binding(
                        get: {
                            let vals = answer?.nestedValue?[group.label] ?? []
                            return Set(vals.map { DynamicOption(rawValue: $0) })
                        },
                        set: { newSet in
                            var a = answer ?? CustomAnswer(questionId: question.id)
                            var nested = a.nestedValue ?? [:]
                            nested[group.label] = Array(newSet.map(\.rawValue))
                            a.nestedValue = nested
                            upsertInPlace(a)
                        }
                    )
                )
                if answer?.nestedValue?[group.label]?.contains("其他") == true {
                    TextField("其他（請填寫）", text: Binding(
                        get: { answer?.nestedOtherText?[group.label] ?? "" },
                        set: { newText in
                            var a = answer ?? CustomAnswer(questionId: question.id)
                            var texts = a.nestedOtherText ?? [:]
                            texts[group.label] = newText
                            a.nestedOtherText = texts
                            upsertInPlace(a)
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    // MARK: - Helpers

    private var answer: CustomAnswer? {
        answers.first { $0.questionId == question.id }
    }

    private func upsertAnswer<V>(_ update: @escaping (inout CustomAnswer, V) -> Void) -> (V) -> Void {
        { value in
            var a = answer ?? CustomAnswer(questionId: question.id)
            update(&a, value)
            upsertInPlace(a)
        }
    }

    private func upsertInPlace(_ a: CustomAnswer) {
        if let idx = answers.firstIndex(where: { $0.questionId == question.id }) {
            answers[idx] = a
        } else {
            answers.append(a)
        }
    }
}
