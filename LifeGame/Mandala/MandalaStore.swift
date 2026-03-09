import Foundation
import Combine
import SwiftUI
import Combine

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
        self.doc = StorageManager.load(Document.self, forKey: key) ?? .empty()
    }
    
    private func save() {
        StorageManager.save(doc, forKey: key)
    }
    
    func reset() {
        doc = .empty()
    }
}
