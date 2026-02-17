import SwiftUI

struct CalendarSettingsView: View {
    @ObservedObject var settings: CalendarSettingsStore
    
    var body: some View {
        Form {
            Section("週起始日") {
                Picker("第一天", selection: $settings.firstWeekday) {
                    Text("週日").tag(1)
                    Text("週一").tag(2)
                    Text("週二").tag(3)
                    Text("週三").tag(4)
                    Text("週四").tag(5)
                    Text("週五").tag(6)
                    Text("週六").tag(7)
                }
                .pickerStyle(.inline)
            }
        }
        .navigationTitle("行事曆設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}
