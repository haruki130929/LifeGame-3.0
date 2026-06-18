import Foundation

enum SharedConstants {
    static let appGroupID = "group.com.haruki.lifegame"

    /// iOS 與 watchOS 共用的 UserDefaults（透過 App Groups）
    /// 如果 App Group 尚未在 Xcode 中啟用，會 fallback 到 standard
    static var sharedDefaults: UserDefaults {
        if let shared = UserDefaults(suiteName: appGroupID) {
            return shared
        } else {
            debugLog("⚠️ App Group '\(appGroupID)' 無法建立，使用 .standard fallback（Watch 同步將無法運作）")
            return .standard
        }
    }

    // MARK: - Shared Keys

    enum Keys {
        static let stats = "shared.stats"
        static let mood = "shared.mood"
        static let todos = "shared.todos"

        // Watch → iOS 變更時間戳
        static let watchMoodUpdatedAt = "shared.watchMoodUpdatedAt"
        static let watchTodosUpdatedAt = "shared.watchTodosUpdatedAt"

        // Widget 設定：待辦 widget 顯示哪個象限（TodoQuadrant rawValue）
        static let widgetTodoQuadrant = "widget.todoQuadrant"
        // Widget 設定：外觀（0=跟隨系統, 1=淺色, 2=深色）
        static let widgetAppearance = "widget.appearance"
    }
}
