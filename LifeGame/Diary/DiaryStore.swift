import Foundation
import Combine
import SwiftUI

@MainActor
final class DiaryStore: ObservableObject {
    @Published private(set) var entries: [DiaryEntry] {
        didSet { save() }
    }

    private let key = "diary_entries_v1"

    init() {
        if let saved: [DiaryEntry] = StorageManager.load([DiaryEntry].self, forKey: key) {
            self.entries = saved
        } else {
            self.entries = []
        }
    }

    // MARK: - CRUD

    func add(_ entry: DiaryEntry) {
        entries.insert(entry, at: 0)
    }

    func update(_ entry: DiaryEntry) {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[i] = entry
        }
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
    }

    // MARK: - Persistence

    private func save() {
        StorageManager.save(entries, forKey: key)
    }
}
