import Foundation
import Combine
import SwiftUI

@MainActor
final class KyudoNoteStore: ObservableObject {
    @Published var notes: [KyudoNote] = []
    
    private let storageKey = "kyudo_notes_v1" // 用 key 取代檔名
    
    init() {
        load()
    }
    
    func add(_ note: KyudoNote) {
        notes.insert(note, at: 0)
        save()
    }
    
    func update(_ note: KyudoNote) {
        guard let idx = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[idx] = note
        save()
    }
    
    func delete(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
        save()
    }
    
    // MARK: - Persistence (SwiftData via StorageManager)
    
    private func load() {
        if let saved: [KyudoNote] = StorageManager.load([KyudoNote].self, forKey: storageKey) {
            notes = saved
        } else {
            notes = []
        }
    }
    
    private func save() {
        StorageManager.save(notes, forKey: storageKey)
    }
}
