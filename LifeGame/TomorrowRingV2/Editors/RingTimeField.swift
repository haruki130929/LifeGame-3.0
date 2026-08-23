import SwiftUI

// MARK: - RingTimeField

/// 圓環編輯器共用的「時：分」輸入列。
///
/// Mac Catalyst 上 `DatePicker` 的 compact 樣式放在 sheet 的 `Form` 裡按下去不會展開，
/// 等於整個時間欄位無法編輯；Mac 改用兩個 menu `Picker`（小時 / 分鐘），滑鼠點一下就能選。
/// 分鐘級距沿用 `RingTimeHelpers.snapStep`，跟圓環拖曳的吸附與 `save()` 的 `snap()` 一致，
/// 所以選單裡看到的時間就是實際會存下去的時間。
/// iPhone / iPad 維持原本的 `DatePicker`。
struct RingTimeField: View {
    let title: String
    @Binding var date: Date

    /// 顯示用：先吸附到級距，既有的非整點資料（例如匯入的課表）才不會落在選項之外變成空白選單
    private var snappedMinuteOfDay: Int {
        RingTimeHelpers.snap(RingTimeHelpers.minute(from: date))
    }
    private var hour: Int { (snappedMinuteOfDay / 60) % 24 }
    private var minute: Int { snappedMinuteOfDay % 60 }

    private static let minuteOptions: [Int] =
        Array(stride(from: 0, to: 60, by: RingTimeHelpers.snapStep))

    private func set(hour h: Int, minute m: Int) {
        date = RingTimeHelpers.date(from: (h % 24) * 60 + m, reference: date)
    }

    var body: some View {
        if AppLayout.isMacCatalyst {
            HStack {
                Text(title)
                Spacer()

                Picker("小時", selection: Binding(
                    get: { hour },
                    set: { set(hour: $0, minute: minute) }
                )) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(String(format: "%02d", h)).tag(h)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)

                // verbatim：冒號只是排版符號，不該被抽進 String Catalog 當成待翻譯字串
                Text(verbatim: ":")
                    .foregroundStyle(.secondary)

                Picker("分鐘", selection: Binding(
                    get: { minute },
                    set: { set(hour: hour, minute: $0) }
                )) {
                    ForEach(Self.minuteOptions, id: \.self) { m in
                        Text(String(format: "%02d", m)).tag(m)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
        } else {
            DatePicker(title, selection: $date, displayedComponents: .hourAndMinute)
        }
    }
}
