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
    private var syncHelper: StoreSyncHelper?

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
            // 極端情況：用最簡化設定再試一次（仍做 do-catch 防護）
            do {
                let container = try ModelContainer(for: DailyLogRecord.self)
                return ModelContext(container)
            } catch {
                // 所有初始化都失敗，這是不可恢復的錯誤
                fatalError("❌ DailyLogStore: 所有 ModelContainer 配置都失敗: \(error)")
            }
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
        // 延遲載入，避免在 observer 掛載前觸發 UI 更新
        Task { @MainActor [weak self] in
            self?.load()
        }
        // 監聽 CloudKit 遠端變更，自動重新載入
        syncHelper = StoreSyncHelper { [weak self] in
            self?.load()
        }
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
    
    /// 刪除指定日期之後的紀錄
    func deleteAfter(_ cutoffDate: Date) {
        do {
            let cal = Calendar.current
            let cutoff = cal.startOfDay(for: cutoffDate)
            let descriptor = FetchDescriptor<DailyLogRecord>()
            let records = try context.fetch(descriptor)
            var count = 0
            for record in records {
                if record.entry.date >= cutoff {
                    context.delete(record)
                    count += 1
                }
            }
            try context.save()
            load()
            debugLog("✅ DailyLog 清除 \(cutoff) 之後的紀錄，共刪除 \(count) 筆")
        } catch {
            debugLog("DailyLogStore deleteAfter failed:", error)
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

            // 去重（在背景做，不影響 UI）
            let needsDedup = deduplicateRecords(records)

            let finalRecords: [DailyLogRecord]
            if needsDedup {
                try context.save()
                finalRecords = try context.fetch(descriptor)
            } else {
                finalRecords = records
            }

            var arr: [DailyLogEntry] = finalRecords.map { $0.entry }
            arr.sort { $0.date > $1.date }
            self.entries = arr
        } catch {
            debugLog("DailyLogStore load failed:", error)
        }
    }

    /// 去重，回傳是否有刪除任何 record
    @discardableResult
    private func deduplicateRecords(_ records: [DailyLogRecord]) -> Bool {
        var deleted = false

        // 同一個 id 有多筆時，刪掉多餘的
        let groupedById = Dictionary(grouping: records, by: \.id)
        for (_, dups) in groupedById where dups.count > 1 {
            for dup in dups.dropFirst() {
                context.delete(dup)
                deleted = true
            }
        }

        // 同一天有不同 id 的紀錄時，保留最後一筆
        let cal = Calendar.current
        let remaining = records.filter { !$0.isDeleted }
        let groupedByDay = Dictionary(grouping: remaining) { r in
            cal.startOfDay(for: r.date)
        }
        for (_, dayRecords) in groupedByDay where dayRecords.count > 1 {
            for dup in dayRecords.dropLast() {
                context.delete(dup)
                deleted = true
                debugLog("🧹 DailyLog 去重：刪除同一天的重複紀錄 \(dup.date)")
            }
        }

        return deleted
    }
}
