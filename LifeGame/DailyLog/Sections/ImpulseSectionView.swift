import SwiftUI

struct ImpulseSectionView: View {
    @Binding var entry: DailyLogEntry
    var header: String = "衝動行為"

    var body: some View {
        Section(header) {
            // 「無」：勾了就清空其他
            CheckboxRow(
                title: "無",
                isChecked: Binding(
                    get: { entry.impulseSeverities.isEmpty },
                    set: { isOn in
                        if isOn {
                            entry.impulseSeverities.removeAll()
                            entry.impulseTypesBySeverity.removeAll()
                            entry.impulseOtherTextBySeverity.removeAll()
                        }
                    }
                )
            )

            // 多選程度（輕微/中等/嚴重）
            VStack(alignment: .leading, spacing: 8) {
                Text("程度（可複選）")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(ImpulseSeverity.allCases) { sev in
                    CheckboxRow(
                        title: sev.rawValue,
                        isChecked: Binding(
                            get: { entry.impulseSeverities.contains(sev) },
                            set: { isOn in
                                if isOn {
                                    entry.impulseSeverities.insert(sev)
                                } else {
                                    entry.impulseSeverities.remove(sev)
                                    entry.impulseTypesBySeverity[sev] = nil
                                    entry.impulseOtherTextBySeverity[sev] = nil
                                }
                            }
                        )
                    )

                    // 勾了某個程度 → 顯示該程度的衝動行為選項
                    if entry.impulseSeverities.contains(sev) {
                        CheckboxMultiSelectList(
                            title: "\(sev.rawValue) 的衝動行為（可複選）",
                            options: ImpulseType.allCases,
                            selected: Binding(
                                get: { entry.impulseTypesBySeverity[sev] ?? [] },
                                set: { entry.impulseTypesBySeverity[sev] = $0 }
                            )
                        )

                        // 其他（填空）
                        let selectedSet = entry.impulseTypesBySeverity[sev] ?? []
                        if selectedSet.contains(.other) {
                            TextField(
                                "其他（請填寫）",
                                text: Binding(
                                    get: { entry.impulseOtherTextBySeverity[sev] ?? "" },
                                    set: { entry.impulseOtherTextBySeverity[sev] = $0 }
                                )
                            )
                        }
                    }
                }
            }
        }
    }
}
