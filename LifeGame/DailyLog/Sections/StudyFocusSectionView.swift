import SwiftUI

struct StudyFocusSectionView: View {
    @Binding var entry: DailyLogEntry
    var header: String = String(localized: "課業與專注力")

    var body: some View {
        Section(header) {
            // 1) 是否完成今日待辦事項（單選）
            CheckboxSingleSelectList(
                title: String(localized: "是否完成今日待辦事項（單選）"),
                options: TodoCompletion.allCases,
                selection: $entry.todoCompletion
            )

            if entry.todoCompletion == .partial {
                HStack {
                    Text("部分完成")
                    Spacer()

                    TextField("完成", value: $entry.todoPartialDone, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)

                    Text("/")

                    TextField("總數", value: $entry.todoPartialTotal, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)

                    Text("項")
                }
            }

            // 2) 今日專注度（單選）
            CheckboxSingleSelectList(
                title: String(localized: "今日專注度（單選）"),
                options: FocusQuality.allCases,
                selection: $entry.focusQuality
            )

            if entry.focusQuality == .cannotFocus {
                // 可能原因（多選）
                CheckboxMultiSelectList(
                    title: String(localized: "可能原因（可複選）"),
                    options: CannotFocusReason.allCases,
                    selected: $entry.cannotFocusReasons
                )

                if entry.cannotFocusReasons.contains(.other) {
                    TextField("其他原因（請填寫）", text: $entry.cannotFocusOtherText)
                }
            }

            // 3) 今日未完成事項（單選：無 / 有）
            VStack(alignment: .leading, spacing: 8) {
                Text("今日未完成事項（單選）")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                CheckboxRow(
                    title: String(localized: "無"),
                    isChecked: Binding(
                        get: { entry.unfinished == false },
                        set: { isOn in if isOn { entry.unfinished = false } }
                    )
                )

                CheckboxRow(
                    title: String(localized: "有"),
                    isChecked: Binding(
                        get: { entry.unfinished == true },
                        set: { isOn in if isOn { entry.unfinished = true } }
                    )
                )
            }

            if entry.unfinished {
                HStack {
                    Text("未完成")
                    Spacer()

                    TextField("未完成", value: $entry.unfinishedCount, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)

                    Text("/")

                    TextField("總數", value: $entry.unfinishedTotal, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)

                    Text("項")
                }

                // 遇到的困難（多選）
                CheckboxMultiSelectList(
                    title: String(localized: "遇到的困難（可複選）"),
                    options: DifficultyReason.allCases,
                    selected: $entry.difficultyReasons
                )

                if entry.difficultyReasons.contains(.other) {
                    TextField("其他困難（請填寫）", text: $entry.difficultyOtherText)
                }
            }
        }
    }
}
