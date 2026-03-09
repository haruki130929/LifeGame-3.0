import SwiftUI
import Combine

@MainActor
final class MoodStore: ObservableObject {
    
    private static let storageKey = "mood_score_v1"
    
    @Published var score: Double = 5 {
        didSet { save() }
    }
    
    init() {
        load()
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
