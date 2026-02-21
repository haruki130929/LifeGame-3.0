import SwiftUI

@main
struct LifeGameApp: App {
    
    @StateObject private var theme = ThemeStore()
    @StateObject private var calendarStore = CalendarStore()
    @StateObject private var calendarSettings = CalendarSettingsStore()
    @StateObject private var fab = FabStore()
    
    var body: some Scene {
        WindowGroup {
            RootShellView()
                .environmentObject(theme)
                .environmentObject(calendarStore)
                .environmentObject(calendarSettings)
                .environmentObject(fab)
        }
    }
}
