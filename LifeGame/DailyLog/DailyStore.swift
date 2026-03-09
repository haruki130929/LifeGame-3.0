import Foundation
import Combine
import SwiftUI
import SwiftData

@MainActor
final class DailyLogStore: ObservableObject {
    
    @Published private(set) var entries: [DailyLogEntry] = []
    
    private let context: ModelContext
    private var isLoading = false
    
    init(context: ModelContext? = nil) {
        if let context {
            self.context = context
        } else {
            guard let coord = StorageManager.coordinator else {
                fatalError("StorageCoordinator 尚未初始化")
            }
            self.context = ModelContext(coord.modelContainer)
        }
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
        do {
            let descriptor = FetchDescriptor<DailyLogRecord>(
                predicate: #Predicate { $0.id == entry.id }
            )
            let existing = try context.fetch(descriptor).first
            
            if let existing {
                existing.update(entry: entry)   // ✅ 對上 DailyLogRecord 相容層
            } else {
                context.insert(DailyLogRecord(entry: entry))
            }
            
            try context.save()
            load()
        } catch {
            print("DailyLogStore upsert failed:", error)
        }
    }
    
    func delete(at offsets: IndexSet) {
        do {
            let items = offsets.compactMap { idx in
                entries.indices.contains(idx) ? entries[idx] : nil
            }
            
            for e in items {
                let descriptor = FetchDescriptor<DailyLogRecord>(
                    predicate: #Predicate { $0.id == e.id }
                )
                if let record = try context.fetch(descriptor).first {
                    context.delete(record)
                }
            }
            
            try context.save()
            load()
        } catch {
            print("DailyLogStore delete failed:", error)
        }
    }
    
    private func load() {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let descriptor = FetchDescriptor<DailyLogRecord>()
            let records = try context.fetch(descriptor)
            
            var arr: [DailyLogEntry] = records.map { $0.entry } // ✅ 需要 DailyLogRecord.entry
            arr.sort { $0.date > $1.date }
            self.entries = arr
        } catch {
            print("DailyLogStore load failed:", error)
            self.entries = []
        }
    }
}
