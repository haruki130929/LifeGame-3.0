import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var dataStore: WatchDataStore

    var body: some View {
        TabView {
            WatchStatusView()
                .tag(0)

            WatchMoodView()
                .tag(1)

            WatchTodoView()
                .tag(2)
        }
        .tabViewStyle(.verticalPage)  // watchOS 垂直翻頁
    }
}
