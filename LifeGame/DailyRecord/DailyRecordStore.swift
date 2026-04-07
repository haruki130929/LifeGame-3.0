import Foundation
import Combine

@MainActor
final class DailyRecordStore: ObservableObject {
    private static let storageKey = "daily_records_v1"
    private var syncHelper: StoreSyncHelper?
    private var isReloading = false

    // key: "2025-12-30"
    @Published private(set) var records: [String: DailyRecord] = [:] {
        didSet { if !isReloading { save() } }
    }

    init() {
        load()
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    func reloadFromStorage() {
        isReloading = true
        defer { isReloading = false }
        if let saved: [String: DailyRecord] = StorageManager.load([String: DailyRecord].self, forKey: Self.storageKey) {
            records = saved
        }
    }
    
    func record(for date: Date) -> DailyRecord? {
        records[key(for: date)]
    }
    
    func upsert(_ record: DailyRecord) {
        records[key(for: record.date)] = record
    }
    
    func delete(for date: Date) {
        records.removeValue(forKey: key(for: date))
    }
    
    // 讓列表好排序
    func allSorted() -> [DailyRecord] {
        records.values.sorted { $0.date > $1.date }
    }
    
    // MARK: - Helpers
    private func key(for date: Date) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        let d = comps.day ?? 0
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
    
    private func save() {
        StorageManager.save(records, forKey: Self.storageKey)
    }
    
    private func load() {
        if let saved: [String: DailyRecord] = StorageManager.load([String: DailyRecord].self, forKey: Self.storageKey) {
            records = saved
        }
    }
}
