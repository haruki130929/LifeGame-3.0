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

    /// 建立 14 天的假數據（用來預覽圖表效果）
    func createSampleData() {
        guard entries.isEmpty else { return }
        let cal = Calendar.current

        for dayOffset in (-13)...0 {
            let date = cal.date(byAdding: .day, value: dayOffset, to: cal.startOfDay(for: Date()))!
            var e = DailyLogEntry()
            e.id = UUID()
            e.date = date

            // 情緒（隨機波動 3-8）
            e.overallMoodScore = Int.random(in: 3...8)
            e.anxietyScore = Int.random(in: 2...7)
            e.fatigueScore = Int.random(in: 2...6)

            // 睡眠（5.5-9 小時）
            e.sleepHours = .value(Double.random(in: 5.5...9.0))

            // 起床/就寢
            let wakeHour = Int.random(in: 6...9)
            let bedHour = Int.random(in: 21...24)
            e.wakeTime = .time(cal.date(bySettingHour: wakeHour, minute: Int.random(in: 0...59), second: 0, of: date)!)
            e.bedTime = .time(cal.date(bySettingHour: bedHour == 24 ? 0 : bedHour, minute: Int.random(in: 0...59), second: 0, of: date)!)

            // 待辦完成度（有些天有，有些沒有）
            if Bool.random() {
                let total = Int.random(in: 3...8)
                e.todoPartialTotal = total
                e.todoPartialDone = Int.random(in: 1...total)
            }

            // 身體不適（偶爾有）
            if Int.random(in: 0...3) == 0 {
                let area: PainArea = [.headache, .stomachache, .muscleTension].randomElement()!
                e.painAreas = [area]
                e.painScoreByArea = [area: Int.random(in: 2...7)]
            }

            upsert(e)
        }
        debugLog("✅ DailyLog 假數據建立完成（14 天）")
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
