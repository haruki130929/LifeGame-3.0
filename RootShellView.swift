import SwiftUI

struct RootShellView: View {
    var body: some View {
        // 讓 HomeRootView 裡的 NavigationLink 有一個導航容器可以 push
        NavigationStack {
            HomeRootView()
        }
    }
}
