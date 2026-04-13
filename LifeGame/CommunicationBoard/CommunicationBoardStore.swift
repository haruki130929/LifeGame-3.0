import Foundation
import SwiftUI
import Combine

@MainActor
final class CommunicationBoardStore: ObservableObject {

    @Published var phrases: [String] {
        didSet { if !isReloading { save() } }
    }

    private let key = "communication_board_phrases_v1"
    private var syncHelper: StoreSyncHelper?
    private var isReloading = false

    init() {
        phrases = StorageManager.load([String].self, forKey: key) ?? Self.defaultPhrases
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    func reloadFromStorage() {
        isReloading = true
        defer { isReloading = false }
        phrases = StorageManager.load([String].self, forKey: key) ?? Self.defaultPhrases
    }

    func add(_ phrase: String) {
        let t = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !phrases.contains(t) else { return }
        phrases.append(t)
    }

    func delete(at offsets: IndexSet) {
        phrases.remove(atOffsets: offsets)
    }

    func move(from source: IndexSet, to destination: Int) {
        phrases.move(fromOffsets: source, toOffset: destination)
    }

    private func save() {
        StorageManager.save(phrases, forKey: key)
    }

    static let defaultPhrases: [String] = [
        "你好",
        "謝謝",
        "不好意思",
        "我想要...",
        "可以請你...",
        "我不舒服",
        "等一下",
        "好",
        "不要",
        "我需要幫忙",
    ]
}
