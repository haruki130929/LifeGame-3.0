import Foundation

@Observable
final class StorageConfiguration: @unchecked Sendable {
    private enum Keys {
        static let storageMode = "lifegame.storage.mode"
    }

    private let defaults: UserDefaults

    private(set) var currentMode: StorageMode

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let raw = defaults.string(forKey: Keys.storageMode) ?? StorageMode.local.rawValue
        self.currentMode = StorageMode(rawValue: raw) ?? .local
    }

    func setMode(_ mode: StorageMode) {
        defaults.set(mode.rawValue, forKey: Keys.storageMode)
        currentMode = mode
    }
}
