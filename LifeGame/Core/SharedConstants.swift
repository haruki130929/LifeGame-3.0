import Foundation

enum SharedConstants {
    static let appGroupID = "group.com.haruki.lifegame"

    /// iOS 與 watchOS 共用的 UserDefaults（透過 App Groups）
    /// 如果 App Group 尚未在 Xcode 中啟用，會 fallback 到 standard
    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    // MARK: - Shared Keys

    enum Keys {
        static let stats = "shared.stats"
        static let mood = "shared.mood"
        static let todos = "shared.todos"
    }
}
