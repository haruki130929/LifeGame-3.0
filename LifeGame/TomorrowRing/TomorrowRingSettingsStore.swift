import Foundation
import Combine

@MainActor
final class TomorrowRingSettingsStore: ObservableObject {
    private enum Keys {
        static let showSegmentIcons = "ring_showSegmentIcons"
    }

    /// 是否在圓環時段上顯示 icon
    @Published var showSegmentIcons: Bool = true {
        didSet {
            if !isReloading { StorageManager.save(showSegmentIcons, forKey: Keys.showSegmentIcons) }
        }
    }

    private var syncHelper: StoreSyncHelper?
    private var isReloading = false

    init() {
        showSegmentIcons = StorageManager.load(Bool.self, forKey: Keys.showSegmentIcons) ?? true
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    // MARK: - Cross-device Sync

    func reloadFromStorage() {
        isReloading = true
        defer { isReloading = false }
        showSegmentIcons = StorageManager.load(Bool.self, forKey: Keys.showSegmentIcons) ?? true
    }
}
