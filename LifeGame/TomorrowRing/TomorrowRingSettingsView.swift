import SwiftUI

struct TomorrowRingSettingsView: View {
    @ObservedObject var settings: TomorrowRingSettingsStore

    var body: some View {
        Form {
            Section {
                Toggle("顯示時段圖示", isOn: $settings.showSegmentIcons)
            } header: {
                Text("圓環顯示")
            } footer: {
                Text("開啟後會在功能頁的圓環時段上顯示對應圖示")
            }
        }
        .navigationTitle("時間圓環設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}
