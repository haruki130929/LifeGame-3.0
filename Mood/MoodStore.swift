import SwiftUI

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
        UserDefaults.standard.set(score, forKey: Self.storageKey)
    }
    
    private func load() {
        if UserDefaults.standard.object(forKey: Self.storageKey) != nil {
            score = UserDefaults.standard.double(forKey: Self.storageKey)
        }
    }
}
