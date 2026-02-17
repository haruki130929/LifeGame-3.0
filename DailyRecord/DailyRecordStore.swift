import Foundation

@MainActor
final class DailyRecordStore: ObservableObject {
    private static let storageKey = "daily_records_v1"
    
    // key: "2025-12-30"
    @Published private(set) var records: [String: DailyRecord] = [:] {
        didSet { save() }
    }
    
    init() { load() }
    
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
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            print("DailyRecordStore save failed:", error)
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return }
        do {
            records = try JSONDecoder().decode([String: DailyRecord].self, from: data)
        } catch {
            print("DailyRecordStore load failed:", error)
        }
    }
}
