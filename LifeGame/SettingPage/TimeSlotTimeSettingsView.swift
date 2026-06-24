import SwiftUI

/// 設定每個時段的開始時間
/// 打開 App 時會依目前時間自動切換到所屬時段。
struct TimeSlotTimeSettingsView: View {

    @EnvironmentObject private var slotTimeStore: TimeSlotTimeStore
    @EnvironmentObject private var slotNameStore: TimeSlotNameStore

    var body: some View {
        Form {
            Section {
                ForEach(TimeSlot.allCases) { slot in
                    DatePicker(
                        selection: binding(for: slot),
                        displayedComponents: .hourAndMinute
                    ) {
                        Label(slotNameStore.displayName(for: slot), systemImage: slot.systemImage)
                    }
                }
            } header: {
                Text("時段開始時間")
            } footer: {
                Text("打開 App 時會自動切換到目前時間所屬的時段。每個時段從你設定的時間開始，直到下一個時段開始為止；最後一個時段會跨夜延續到隔天清晨。")
            }

            Section {
                Button(role: .destructive) {
                    slotTimeStore.resetAll()
                } label: {
                    Label("回復預設時間", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle("時段時間")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func binding(for slot: TimeSlot) -> Binding<Date> {
        Binding(
            get: { slotTimeStore.startTime(for: slot) },
            set: { slotTimeStore.setStartTime($0, for: slot) }
        )
    }
}
