import Foundation

@Observable
final class StorageConfiguration: @unchecked Sendable {
    private enum Keys {
        static let storageMode = "lifegame.storage.mode"
        static let pendingMode = "lifegame.storage.pendingMode"
        static let keychainStorageMode = "lifegame.storage.mode" // Keychain key
    }

    private let defaults: UserDefaults

    private(set) var currentMode: StorageMode
    private(set) var pendingMode: StorageMode?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // 優先從 UserDefaults 讀取；若不存在（首次安裝或重裝後），從 Keychain 回復
        let raw: String
        if let udMode = defaults.string(forKey: Keys.storageMode) {
            raw = udMode
        } else if let keychainMode = KeychainHelper.load(forKey: Keys.keychainStorageMode) {
            // 從 Keychain 回復（App 曾被刪除重裝）
            raw = keychainMode
            defaults.set(keychainMode, forKey: Keys.storageMode)
            debugLog("🔑 從 Keychain 回復儲存模式：\(keychainMode)")
        } else {
            // 首次安裝：如果 iCloud 可用就預設用 iCloud，確保資料從一開始就同步到雲端
            if FileManager.default.ubiquityIdentityToken != nil {
                raw = StorageMode.iCloud.rawValue
                defaults.set(raw, forKey: Keys.storageMode)
                KeychainHelper.save(raw, forKey: Keys.keychainStorageMode)
                debugLog("☁️ 首次安裝，iCloud 可用，預設使用 iCloud 儲存")
            } else {
                raw = StorageMode.local.rawValue
            }
        }

        self.currentMode = StorageMode(rawValue: raw) ?? .local

        // 確保 Keychain 永遠有最新的儲存模式（補上舊版本沒存到的情況）
        KeychainHelper.save(currentMode.rawValue, forKey: Keys.keychainStorageMode)

        if let pendingRaw = defaults.string(forKey: Keys.pendingMode) {
            self.pendingMode = StorageMode(rawValue: pendingRaw)
        }
    }

    func setMode(_ mode: StorageMode) {
        defaults.set(mode.rawValue, forKey: Keys.storageMode)
        // 同時存到 Keychain，確保刪除 App 後重裝能回復
        KeychainHelper.save(mode.rawValue, forKey: Keys.keychainStorageMode)
        currentMode = mode
    }

    // MARK: - Pending mode（重啟後生效）

    func setPendingMode(_ mode: StorageMode) {
        defaults.set(mode.rawValue, forKey: Keys.pendingMode)
        pendingMode = mode
    }

    func clearPendingMode() {
        defaults.removeObject(forKey: Keys.pendingMode)
        pendingMode = nil
    }

    /// 遷移完成後呼叫：把 pending 變成 current
    func confirmModeSwitch() {
        guard let pending = pendingMode else { return }
        setMode(pending)
        clearPendingMode()
    }
}
