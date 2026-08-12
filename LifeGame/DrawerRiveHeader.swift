import SwiftUI
#if canImport(RiveRuntime)
import RiveRuntime
#endif

/// 左側抽屜頂部的動畫 header。
///
/// 目前用的是「暫時的」測試素材：drawer_header.riv 是 Rive 官方 rive-ios repo 的
/// rating_animation.riv 範例檔（五顆星評分動畫），只是用來驗證整條串接有沒有通。
/// 之後換成自己在 Rive 編輯器做的動畫時，改下面三個常數就好。
///
/// 沒裝 RiveRuntime 套件、或找不到 .riv 檔時，會自動退回靜態圖示，專案照樣能編譯執行。
struct DrawerRiveHeader: View {
    /// .riv 檔名（不含副檔名）
    static let riveFileName = "drawer_header"
    /// 狀態機名稱，要跟 Rive 編輯器裡一字不差
    static let stateMachineName = "State Machine 1"
    /// 這個範例檔的 Number input（0–5，控制亮幾顆星）
    static let ratingInputName = "rating"

    @EnvironmentObject private var theme: ThemeStore

    private var riveFileExists: Bool {
        Bundle.main.url(forResource: Self.riveFileName, withExtension: "riv") != nil
    }

    var body: some View {
        Group {
            #if canImport(RiveRuntime)
            if riveFileExists {
                RiveContent()
            } else {
                fallback
            }
            #else
            fallback
            #endif
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
    }

    /// 還沒接上 Rive 時顯示的靜態版本
    private var fallback: some View {
        VStack(spacing: 6) {
            Image(systemName: "sparkles")
                // Mac Catalyst 沒有 Dynamic Type，字級用固定點數
                .font(.system(size: 34))
                .foregroundStyle(theme.accentColor)
            Text("LifeGame")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

#if canImport(RiveRuntime)
/// 真正播放 Rive 動畫的部分。
/// 只在 .riv 檔確定存在時才建立 —— RiveViewModel 的 init 內部是 `try! RiveModel(fileName:)`，
/// 檔案不存在會直接 crash 而不是顯示空白。
private struct RiveContent: View {
    @StateObject private var rive = RiveViewModel(
        fileName: DrawerRiveHeader.riveFileName,
        stateMachineName: DrawerRiveHeader.stateMachineName
    )

    /// 目前亮幾顆星，點一下加一顆，滿五顆繞回一顆
    @State private var rating: Float = 5

    var body: some View {
        rive.view()
            .contentShape(Rectangle())
            .onTapGesture {
                rating = rating >= 5 ? 1 : rating + 1
                apply(rating)
            }
            .onAppear { apply(rating) }
    }

    /// 用安全的具名存取器設定 input。
    ///
    /// 刻意不用 `rive.setInput(_:value:)` / `rive.triggerInput(_:)`：
    /// 那兩個內部是 `stateMachine?.getNumber(name).setValue(...)`，而 ObjC 標頭把
    /// getNumber/getTrigger 宣告在 NS_ASSUME_NONNULL 區塊裡，名稱打錯會變成
    /// nil 塞進非 optional 而 crash。`numberInput(named:)` 回傳 optional，安全得多。
    private func apply(_ value: Float) {
        guard let input = rive.numberInput(named: DrawerRiveHeader.ratingInputName) else {
            debugLog("⚠️ Rive：在狀態機「\(DrawerRiveHeader.stateMachineName)」找不到名為「\(DrawerRiveHeader.ratingInputName)」的 number input")
            return
        }
        input.setValue(value)
        rive.play()
    }
}
#endif
