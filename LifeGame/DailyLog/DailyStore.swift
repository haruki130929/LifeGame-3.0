import Foundation
import Combine
import SwiftUI
import SwiftData

@MainActor
final class DailyLogStore: ObservableObject {
    
    @Published private(set) var entries: [DailyLogEntry] = []
    @Published private(set) var initError: String?

    private let context: ModelContext
    private var isLoading = false

    /// 建立 in-memory fallback 容器（StorageCoordinator 不可用時）
    private static func makeInMemoryContext() -> ModelContext {
        // in-memory 容器幾乎不可能失敗，但仍做防護
        do {
            let container = try ModelContainer(
                for: DailyLogRecord.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            return ModelContext(container)
        } catch {
            debugLog("❌ DailyLogStore: in-memory 容器也失敗: \(error)")
            // 極端情況：用最簡化設定再試一次
            let container = try! ModelContainer(for: DailyLogRecord.self)
            return ModelContext(container)
        }
    }

    init(context: ModelContext? = nil) {
        if let context {
            self.context = context
        } else if let coord = StorageManager.coordinator {
            self.context = ModelContext(coord.modelContainer)
        } else {
            debugLog("⚠️ DailyLogStore: StorageCoordinator 尚未初始化，使用 in-memory 容器")
            self.context = Self.makeInMemoryContext()
            self.initError = "儲存系統尚未就緒，資料暫存於記憶體中"
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
            debugLog("DailyLogStore upsert failed:", error)
            ErrorManager.shared.showError(L10n.Error.saveFailed, error: error)
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
            debugLog("DailyLogStore delete failed:", error)
            ErrorManager.shared.showError(L10n.Error.deleteFailed, error: error)
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
            debugLog("DailyLogStore load failed:", error)
            self.entries = []
        }
    }
}
