import Foundation

@Observable
final class StorageConfiguration: @unchecked Sendable {
    private enum Keys {
        static let storageMode = "lifegame.storage.mode"
        static let pendingMode = "lifegame.storage.pendingMode"
    }

    private let defaults: UserDefaults

    private(set) var currentMode: StorageMode
    private(set) var pendingMode: StorageMode?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let raw = defaults.string(forKey: Keys.storageMode) ?? StorageMode.local.rawValue
        self.currentMode = StorageMode(rawValue: raw) ?? .local

        if let pendingRaw = defaults.string(forKey: Keys.pendingMode) {
            self.pendingMode = StorageMode(rawValue: pendingRaw)
        }
    }

    func setMode(_ mode: StorageMode) {
        defaults.set(mode.rawValue, forKey: Keys.storageMode)
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
