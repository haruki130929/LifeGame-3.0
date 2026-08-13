import Foundation

/// v1.20 暫時關閉、之後版本要重新打開的功能開關。
///
/// 只擋 UI 入口，不動儲存層、同步層與 SwiftData schema —— 使用者已經存下的資料
/// 照常保留、照常同步，重新打開時就會直接出現。
///
/// 必須是編譯期常數（`static let`）。不要改成 UserDefaults / @AppStorage：
/// App Store 審查指南 2.3.1 針對的是「不必重新送審就能開啟」的隱藏功能，
/// 編譯進 binary 的常數沒有這個問題。
enum ReleaseFlags {

    /// 任務水族箱（`LifeGame/Aquarium/*`）
    ///
    /// 關閉後 `AquariumPanelView` 不再建立，FAB 也不再出現「水族箱」項目。
    /// `AquariumStore` 仍然存在但不寫入（有 isReloading 保護），
    /// `SyncMergeRegistration` 的 `aquarium_v1` 也保持註冊，否則跨裝置合併會
    /// 從 union-by-id 退化成 last-write-wins 而造成資料遺失。
    static let aquariumEnabled = false

    /// iPad／Mac 儀表板的卡片尺寸選擇器（小／中／大）
    ///
    /// 關閉後卡片編輯頁只剩排序，不再顯示尺寸選項。
    /// 已存下的尺寸照常沿用，`SpanCardGrid` 排版本身不受影響。
    static let cardSizePickerEnabled = false
}
