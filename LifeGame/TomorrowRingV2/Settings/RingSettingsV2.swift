import SwiftUI

// MARK: - RingSettingsV2

struct RingSettingsV2: View {
    @EnvironmentObject private var store: TomorrowRingStore

    var body: some View {
        Form {
            Section("顯示") {
                Toggle("顯示時段圖示", isOn: $store.showSegmentIcons)
            }

            Section("資源") {
                Stepper("基礎 HP：\(store.plan.baseHP)", value: $store.plan.baseHP, in: 50...200, step: 10)
                Stepper("基礎 FP：\(store.plan.baseFP)", value: $store.plan.baseFP, in: 50...200, step: 10)
            }

            Section("操作") {
                Button {
                    store.initializeActualFromPlan()
                } label: {
                    Label("從預定複製到實際", systemImage: "doc.on.doc")
                }

                Button {
                    store.applyClassScheduleIfNeeded()
                } label: {
                    Label("載入今日課表", systemImage: "calendar.badge.plus")
                }
            }

            Section {
                Button(role: .destructive) {
                    store.plan.planItems.removeAll()
                    store.plan.actualItems.removeAll()
                } label: {
                    Label("清空所有時段", systemImage: "trash")
                }
            }
        }
        .navigationTitle("圓環設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}
