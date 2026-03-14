import SwiftUI

struct MoodSettingsView: View {
    @EnvironmentObject private var settings: MoodSettingsStore

    var body: some View {
        Form {
            Section {
                Stepper("最低分：\(settings.minScore)", value: $settings.minScore, in: 0...(settings.maxScore - 1))
                Stepper("最高分：\(settings.maxScore)", value: $settings.maxScore, in: (settings.minScore + 1)...100)
            } header: {
                Text("分數區間")
            } footer: {
                Text("預設為 0～10 分，可依需求自訂。")
            }
        }
        .navigationTitle("心情溫度計設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}
