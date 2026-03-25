import Foundation
import Combine
import SwiftUI

@MainActor
final class PracticeDiaryStore: ObservableObject {
    @Published private(set) var diaries: [PracticeDiary] = []
    @Published private var entriesCache: [UUID: [PracticeEntry]] = [:]

    private let diariesKey = "practice_diaries_v1"

    init() {
        loadDiaries()
    }

    // MARK: - Diary CRUD

    func addDiary(_ diary: PracticeDiary) {
        diaries.insert(diary, at: 0)
        saveDiaries()
    }

    func updateDiary(_ diary: PracticeDiary) {
        guard let idx = diaries.firstIndex(where: { $0.id == diary.id }) else { return }
        diaries[idx] = diary
        saveDiaries()
    }

    func deleteDiary(id: UUID) {
        diaries.removeAll { $0.id == id }
        entriesCache.removeValue(forKey: id)
        StorageManager.remove(forKey: entriesKey(for: id))
        saveDiaries()
    }

    // MARK: - Entry CRUD

    func entries(for diaryId: UUID) -> [PracticeEntry] {
        if let cached = entriesCache[diaryId] {
            return cached
        }
        let loaded: [PracticeEntry] = StorageManager.load([PracticeEntry].self, forKey: entriesKey(for: diaryId)) ?? []
        entriesCache[diaryId] = loaded
        return loaded
    }

    func addEntry(_ entry: PracticeEntry) {
        var list = entries(for: entry.diaryId)
        list.insert(entry, at: 0)
        entriesCache[entry.diaryId] = list
        saveEntries(for: entry.diaryId)
    }

    func updateEntry(_ entry: PracticeEntry) {
        var list = entries(for: entry.diaryId)
        guard let idx = list.firstIndex(where: { $0.id == entry.id }) else { return }
        list[idx] = entry
        entriesCache[entry.diaryId] = list
        saveEntries(for: entry.diaryId)
    }

    func deleteEntries(for diaryId: UUID, at offsets: IndexSet) {
        var list = entries(for: diaryId)
        list.remove(atOffsets: offsets)
        entriesCache[diaryId] = list
        saveEntries(for: diaryId)
    }

    func entryCount(for diaryId: UUID) -> Int {
        entries(for: diaryId).count
    }

    // MARK: - Persistence

    private func loadDiaries() {
        diaries = StorageManager.load([PracticeDiary].self, forKey: diariesKey) ?? []
    }

    private func saveDiaries() {
        StorageManager.save(diaries, forKey: diariesKey)
    }

    private func saveEntries(for diaryId: UUID) {
        guard let list = entriesCache[diaryId] else { return }
        StorageManager.save(list, forKey: entriesKey(for: diaryId))
    }

    private func entriesKey(for diaryId: UUID) -> String {
        "practice_entries_\(diaryId.uuidString)"
    }
}
