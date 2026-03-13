import SwiftUI

struct BasicSectionView: View {
    @Binding var entry: DailyLogEntry
    var header: String = "基本"

    var body: some View {
        Section(header) {
            DatePicker("日期", selection: $entry.date, displayedComponents: .date)

            Picker("天氣", selection: $entry.weather) {
                ForEach(Weather.allCases) { w in
                    Text(w.rawValue).tag(w)
                }
            }

            // 起床時間：可忘記 + 30 分鐘刻度
            HalfHourOptionalTimePickerRow(title: "起床時間", value: $entry.wakeTime)

            // 上床時間：30 分鐘刻度
            HalfHourOptionalTimePickerRow(title: "昨晚上床時間", value: $entry.bedTime)
        }
    }
}
