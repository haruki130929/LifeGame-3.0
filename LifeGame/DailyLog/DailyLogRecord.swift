import Foundation
import SwiftData

@Model
final class DailyLogRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    var payload: Data = Data()

    init(id: UUID, date: Date, payload: Data) {
        self.id = id
        self.date = date
        self.payload = payload
    }

    // 既有：entry -> record
    convenience init(entry: DailyLogEntry) {
        // 編碼失敗時退回空資料（已記錄錯誤，避免完全無聲無息）
        let data = Self.encodeEntry(entry) ?? Data()
        self.init(id: entry.id, date: entry.date, payload: data)
    }

    // ✅ 相容層：外部如果寫 DailyLogRecord(from: entry)
    convenience init(from entry: DailyLogEntry) {
        self.init(entry: entry)
    }

    func decodeEntry() -> DailyLogEntry? {
        Self.decodeEntry(from: payload)
    }

    // ✅ 相容層：外部如果要 record.entry 直接拿到 DailyLogEntry
    // 若 decode 失敗，就回傳一個「至少不會崩」的預設值（id/date 會對齊 record）
    var entry: DailyLogEntry {
        if let e = decodeEntry() { return e }
        var e = DailyLogEntry()
        e.id = id
        e.date = date
        return e
    }

    func update(from entry: DailyLogEntry) {
        // 編碼成功才覆蓋；失敗則保留原本內容，避免把既有資料洗成空白
        guard let data = Self.encodeEntry(entry) else {
            debugLog("⚠️ DailyLogRecord.update 編碼失敗，保留原本內容不覆蓋（id=\(entry.id)）")
            return
        }
        id = entry.id
        date = entry.date
        payload = data
    }

    // ✅ 相容層：外部如果寫 record.update(entry: xxx)
    func update(entry: DailyLogEntry) {
        update(from: entry)
    }

    // MARK: - Nonisolated helpers（避免 Swift 6 concurrency 警告）

    private nonisolated static func encodeEntry(_ entry: DailyLogEntry) -> Data? {
        do {
            return try JSONEncoder().encode(entry)
        } catch {
            debugLog("❌ DailyLogRecord 編碼失敗：\(error)")
            return nil
        }
    }

    private nonisolated static func decodeEntry(from data: Data) -> DailyLogEntry? {
        do {
            return try JSONDecoder().decode(DailyLogEntry.self, from: data)
        } catch {
            debugLog("❌ DailyLogRecord 解碼失敗（payload \(data.count) bytes）：\(error)")
            return nil
        }
    }
}
