import SwiftUI

struct CalendarSettingsView: View {
    @ObservedObject var settings: CalendarSettingsStore

    var body: some View {
        Form {
            Section {
                Picker("一週起始日", selection: $settings.firstWeekday) {
                    Text("週日").tag(1)
                    Text("週一").tag(2)
                }
            } header: {
                Text("顯示")
            }

            Section {
                Toggle("同步 Apple 行事曆", isOn: $settings.syncAppleCalendar)
            } footer: {
                Text("開啟後將顯示 Apple 內建行事曆的行程")
            }
        }
        .navigationTitle("行事曆設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}
