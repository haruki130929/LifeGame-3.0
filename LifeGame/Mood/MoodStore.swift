import SwiftUI
import Combine

@MainActor
final class MoodStore: ObservableObject {
    
    private static let storageKey = "mood_score_v1"

    @Published var score: Double = 5 {
        didSet { if !isReloading { save() } }
    }
    @Published var focus: Double = 5
    @Published var fatigue: Double = 5

    private var syncHelper: StoreSyncHelper?
    private var isReloading = false
    
    init() {
        load()
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    func reloadFromStorage() {
        isReloading = true
        defer { isReloading = false }
        if let saved: Double = StorageManager.load(Double.self, forKey: Self.storageKey) {
            score = saved
        }
    }
    
    func save() {
        StorageManager.save(score, forKey: Self.storageKey)
    }
    
    private func load() {
        if let saved: Double = StorageManager.load(Double.self, forKey: Self.storageKey) {
            score = saved
        }
    }
}
