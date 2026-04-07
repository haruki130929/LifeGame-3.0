import Foundation
import Combine
import SwiftUI

@MainActor
final class MoodSettingsStore: ObservableObject {
    private enum Keys {
        static let minScore = "mood_min_score"
        static let maxScore = "mood_max_score"
    }

    @Published var minScore: Int = 0 {
        didSet { if !isReloading { StorageManager.save(minScore, forKey: Keys.minScore) } }
    }

    @Published var maxScore: Int = 10 {
        didSet { if !isReloading { StorageManager.save(maxScore, forKey: Keys.maxScore) } }
    }

    private var syncHelper: StoreSyncHelper?
    private var isReloading = false

    /// Slider / 圖表使用的區間
    var scoreRange: ClosedRange<Double> {
        Double(minScore)...Double(maxScore)
    }

    init() {
        minScore = StorageManager.load(Int.self, forKey: Keys.minScore) ?? 0
        maxScore = StorageManager.load(Int.self, forKey: Keys.maxScore) ?? 10
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    func reloadFromStorage() {
        isReloading = true
        defer { isReloading = false }
        minScore = StorageManager.load(Int.self, forKey: Keys.minScore) ?? 0
        maxScore = StorageManager.load(Int.self, forKey: Keys.maxScore) ?? 10
    }
}
