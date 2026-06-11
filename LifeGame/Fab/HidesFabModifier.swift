import SwiftUI

/// 在子頁顯示期間隱藏 FAB（「＋」），離開子頁時還原。
///
/// 用途：以 NavigationLink push 進入的「子頁」（例如編輯單筆、圖表、單題編輯）
/// 不該沿用上一層功能頁的「＋」選單。套上 `.hidesFab()` 後，進入子頁就把 FAB 藏起來，
/// 退回上一層時還原成該功能的選單。
///
/// 注意：請套在「push 的目的地」（NavigationLink 內），不要套在被當成 sheet 用的同一個 view，
/// 以確保 `fab` 環境物件一定取得到（sheet 本來就會蓋住 FAB，無需處理）。
struct HidesFabModifier: ViewModifier {
    @EnvironmentObject private var fab: FabStore

    func body(content: Content) -> some View {
        content
            .onAppear { fab.isHidden = true }
            .onDisappear { fab.isHidden = false }
    }
}

extension View {
    /// 子頁顯示期間隱藏「＋」FAB，離開時還原。
    func hidesFab() -> some View {
        modifier(HidesFabModifier())
    }
}
