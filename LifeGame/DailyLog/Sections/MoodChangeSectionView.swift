import SwiftUI

struct MoodChangeSectionView: View {
    @Binding var entry: DailyLogEntry
    var header: String = String(localized: "情緒變化")

    var body: some View {
        Section(header) {
            // 1) 狀態（單選）
            CheckboxSingleSelectList(
                title: String(localized: "狀態（單選）"),
                options: MoodChangeType.allCases,
                selection: $entry.moodChangeType
            )

            // 2) 只有「變高」才顯示細項
            if entry.moodChangeType == .higher {
                // 原因（多選）
                CheckboxMultiSelectList(
                    title: String(localized: "原因（可複選）"),
                    options: MoodChangeReason.allCases,
                    selected: $entry.moodChangeReasons
                )

                // 其他原因填空
                if entry.moodChangeReasons.contains(.other) {
                    TextField("其他原因（請填寫）", text: $entry.moodChangeOtherText)
                }

                // 持續時間（填空）
                TextField("持續時間", text: $entry.moodChangeDurationText)

                // 穩定方式（多選）
                CheckboxMultiSelectList(
                    title: String(localized: "用什麼方式穩定下來（可複選）"),
                    options: StabilizeMethod.allCases,
                    selected: $entry.stabilizeMethodsForMoodChange
                )

                // 其他穩定方式填空
                if entry.stabilizeMethodsForMoodChange.contains(.other) {
                    TextField("其他方式（請填寫）", text: $entry.stabilizeOtherTextForMoodChange)
                }

            } else {
                Text("已選擇「穩定」")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
