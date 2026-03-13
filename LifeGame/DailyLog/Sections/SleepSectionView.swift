import SwiftUI

struct SleepSectionView: View {
    @Binding var entry: DailyLogEntry
    var header: String = "睡眠狀況"

    var body: some View {
        Section(header) {
            // 單選：入睡所需時間
            CheckboxSingleSelectList(
                title: "入睡所需時間（單選）",
                options: SleepLatency.allCases,
                selection: $entry.sleepLatency
            )

            // 睡眠時長：0.5 單位
            OptionalHalfHourNumberPickerRow(
                title: "睡眠時長（小時）",
                value: $entry.sleepHours,
                range: 0...16
            )

            // 單選：睡眠品質
            CheckboxSingleSelectList(
                title: "睡眠品質（單選）",
                options: SleepQuality.allCases,
                selection: $entry.sleepQuality
            )
        }
    }
}
