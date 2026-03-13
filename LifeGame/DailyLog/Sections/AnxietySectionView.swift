import SwiftUI

struct AnxietySectionView: View {
    @Binding var entry: DailyLogEntry
    var header: String = "是否出現焦慮"

    var body: some View {
        Section(header) {
            // 程度（單選）
            CheckboxSingleSelectList(
                title: "程度（單選）",
                options: AnxietyLevel.allCases,
                selection: $entry.anxietyLevel
            )

            if entry.anxietyLevel != .none {
                // 原因（多選）
                CheckboxMultiSelectList(
                    title: "原因（可複選）",
                    options: AnxietyReason.allCases,
                    selected: $entry.anxietyReasons
                )

                if entry.anxietyReasons.contains(.other) {
                    TextField("其他原因（請填寫）", text: $entry.anxietyOtherText)
                }

                // 持續時間（填空）
                TextField("持續時間", text: $entry.anxietyDurationText)

                // 焦慮表現（多選）
                CheckboxMultiSelectList(
                    title: "焦慮表現（可複選）",
                    options: AnxietySymptom.allCases,
                    selected: $entry.anxietySymptoms
                )

                if entry.anxietySymptoms.contains(.other) {
                    TextField("其他表現（請填寫）", text: $entry.anxietySymptomOtherText)
                }

                // 穩定方式（多選）
                CheckboxMultiSelectList(
                    title: "用什麼方式穩定下來（可複選）",
                    options: StabilizeMethod.allCases,
                    selected: $entry.stabilizeMethodsForAnxiety
                )

                if entry.stabilizeMethodsForAnxiety.contains(.other) {
                    TextField("其他方式（請填寫）", text: $entry.stabilizeOtherTextForAnxiety)
                }
            } else {
                Text("已選擇「無」")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
