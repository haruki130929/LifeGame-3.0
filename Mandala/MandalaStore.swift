import Foundation
import SwiftUI

final class MandalaStore: ObservableObject {
    
    struct Document: Codable {
        var goal: String
        var themes: [String]              // 8 個
        var actions: [[String]]           // 8 組，每組 8 個
        
        static func empty() -> Document {
            Document(
                goal: "",
                themes: Array(repeating: "", count: 8),
                actions: Array(repeating: Array(repeating: "", count: 8), count: 8)
            )
        }
    }
    
    @Published var doc: Document {
        didSet { save() }
    }
    
    private let key = "mandala.document.v1"
    
    init() {
        self.doc = Self.load(key: key) ?? .empty()
    }
    
    private static func load(key: String) -> Document? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Document.self, from: data)
    }
    
    private func save() {
        guard let data = try? JSONEncoder().encode(doc) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    func reset() {
        doc = .empty()
    }
}
