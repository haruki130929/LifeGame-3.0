import Foundation
import SwiftUI

@MainActor
final class DailyLogStore: ObservableObject {
    
    private let fileStore: FileStore
    private let filename = "daily_logs_v1.json"
    
    @Published private(set) var entries: [DailyLogEntry] = []
    
    init(fileStore: FileStore = FileStore()) {
        self.fileStore = fileStore
        load()
    }
    
    func addToday() -> DailyLogEntry {
        if let existing = entry(for: Date()) { return existing }
        var e = DailyLogEntry()
        e.date = Date()
        upsert(e)
        return e
    }
    
    func entry(for date: Date) -> DailyLogEntry? {
        let cal = Calendar.current
        return entries.first(where: { cal.isDate($0.date, inSameDayAs: date) })
    }
    
    func upsert(_ entry: DailyLogEntry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[idx] = entry
        } else {
            entries.insert(entry, at: 0)
        }
        entries.sort { $0.date > $1.date }
        save()
    }
    
    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }
    
    private func load() {
        let box = SafeLoad.loadOrDefault(
            store: fileStore,
            filename: filename,
            defaultValue: VersionedBox(version: 1, payload: [DailyLogEntry]())
        )
        
        // v1: payload 就是 [DailyLogEntry]
        entries = box.payload
        entries.sort { $0.date > $1.date }
    }
    
    private func save() {
        do {
            let box = VersionedBox(version: 1, payload: entries)
            try fileStore.save(box, to: filename)
        } catch {
            // 上架版建議：可以加一個 logger，但不要卡 UI
        }
    }
}
