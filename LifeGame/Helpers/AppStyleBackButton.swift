import SwiftUI

/// 功能頁返回鈕：外觀與主頁的「＋」／頂部工具列圓鈕一致（FloatingIconButton 樣式），
/// 按下直接回到主頁面。
///
/// iOS 26 會自動在工具列按鈕後面加一層「Liquid Glass」圓底，導致出現兩層圓圈；
/// 用 `sharedBackgroundVisibility(.hidden)` 把那層玻璃底關掉，只留我們自己的圓鈕。
private struct AppStyleBackButtonModifier: ViewModifier {
    @EnvironmentObject private var navigator: HomeNavigator

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar { backButtonItem }
    }

    @ToolbarContentBuilder
    private var backButtonItem: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .topBarLeading) {
                button
            }
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) {
                button
            }
        }
    }

    private var button: some View {
        FloatingIconButton(systemName: "chevron.backward", size: 52) {
            navigator.popToRoot()
        }
    }
}

extension View {
    /// 把功能頁的返回鈕換成與主頁圓鈕一致的樣式，按下直接回主頁面。
    func appStyleBackButton() -> some View {
        modifier(AppStyleBackButtonModifier())
    }
}
