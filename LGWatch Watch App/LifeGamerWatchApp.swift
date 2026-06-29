import SwiftUI

@main
struct LifeGamerWatch_Watch_AppApp: App {
    @StateObject private var dataStore = WatchDataStore()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(dataStore)
        }
    }
}
