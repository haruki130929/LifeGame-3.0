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
            StorageManager.save(showSegmentIcons, forKey: Keys.showSegmentIcons)
        }
    }

    init() {
        showSegmentIcons = StorageManager.load(Bool.self, forKey: Keys.showSegmentIcons) ?? true
    }
}
