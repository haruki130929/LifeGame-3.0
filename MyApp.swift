import SwiftUI

@main
struct LifeGameApp: App {
    // 這些一定要跟 HomeRootView 的 @EnvironmentObject 對上
    @StateObject private var theme = ThemeStore()
    @StateObject private var calendarStore = CalendarStore()
    @StateObject private var calendarSettings = CalendarSettingsStore()
    @StateObject private var fab = FabStore()
    
    @StateObject private var wishStore = WishStore()
    @StateObject private var ledgerStore = LedgerStore()
    
    var body: some Scene {
        WindowGroup {
            HomeRootView()
                .environmentObject(theme)
                .environmentObject(calendarStore)
                .environmentObject(calendarSettings)
                .environmentObject(fab)
                .environmentObject(wishStore)
                .environmentObject(ledgerStore)
        }
    }
}
