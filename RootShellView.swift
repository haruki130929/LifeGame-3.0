import SwiftUI

struct RootShellView: View {
    
    // 全域共用 stores
    @StateObject private var theme = ThemeStore()
    @StateObject private var calendarStore = CalendarStore()
    @StateObject private var calendarSettings = CalendarSettingsStore()
    
    @StateObject private var fab = FabStore()
    
    @StateObject private var wishStore = WishStore()
    @StateObject private var ledgerStore = LedgerStore()
    
    var body: some View {
        NavigationStack {
            HomeRootView()
        }
        .environmentObject(theme)
        .environmentObject(calendarStore)
        .environmentObject(calendarSettings)
        
        .environmentObject(fab)
        
        .environmentObject(wishStore)
        .environmentObject(ledgerStore)
    }
}
