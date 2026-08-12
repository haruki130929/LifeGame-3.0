import SwiftUI

struct BodySectionView: View {
    @Binding var entry: DailyLogEntry
    var header: String = String(localized: "身體狀況")

    var body: some View {
        Section(header) {
            // 疲勞（Slider）
            ScoreSliderRow(title: String(localized: "今日疲勞程度"), value: $entry.fatigueScore)

            // 不舒服的地方（多選）
            VStack(alignment: .leading, spacing: 8) {
                Text("不舒服的地方（可複選）")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(PainArea.allCases) { area in
                    CheckboxRow(
                        title: area.displayName,
                        isChecked: bindingForSet($entry.painAreas, element: area)
                    )

                    if entry.painAreas.contains(area) {
                        Picker("不適程度（1～10）", selection: bindingForPainScore(area)) {
                            ForEach(1...10, id: \.self) { v in
                                Text("\(v)").tag(v)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)

            // 是否注意到身體狀況（單選）
            CheckboxSingleSelectList(
                title: String(localized: "是否注意到身體的狀況（單選）"),
                options: BodyNoticeTiming.allCases,
                selection: $entry.bodyNoticeTiming
            )

            // 若選「沒有」：原因（多選 + 其他填空）
            if entry.bodyNoticeTiming == .none {
                CheckboxMultiSelectList(
                    title: String(localized: "因為（可複選）"),
                    options: BodyLateReason.allCases,
                    selected: $entry.bodyLateReasons
                )

                if entry.bodyLateReasons.contains(.other) {
                    TextField("其他原因（請填寫）", text: $entry.bodyLateOtherText)
                }
            }
        }
    }

    // MARK: - Helpers

    private func bindingForPainScore(_ area: PainArea) -> Binding<Int> {
        Binding(
            get: { entry.painScoreByArea[area] ?? 1 },
            set: { entry.painScoreByArea[area] = $0 }
        )
    }

    private func bindingForSet<T: Hashable>(_ set: Binding<Set<T>>, element: T) -> Binding<Bool> {
        Binding(
            get: { set.wrappedValue.contains(element) },
            set: { isOn in
                if isOn { set.wrappedValue.insert(element) }
                else { set.wrappedValue.remove(element) }
            }
        )
    }
}
