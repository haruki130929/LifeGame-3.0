import SwiftUI
import Combine

/// 持有功能頁的導航堆疊，由 MyApp 在最上層注入，
/// 讓抽屜、分類頁、功能頁共用同一個堆疊。
@MainActor
final class HomeNavigator: ObservableObject {
    @Published var path = NavigationPath()

    /// 導到某功能頁，並讓它成為堆疊的「唯一一層」。
    /// 這樣在功能頁按系統返回鈕時會直接回到主頁面，
    /// 而不是退回上一層（例如選單分類頁）。
    func go(to feature: FeatureID) {
        var newPath = NavigationPath()
        newPath.append(feature)
        path = newPath
    }

    /// 清空整個導航堆疊，直接回到主頁面。
    func popToRoot() {
        path = NavigationPath()
    }
}
