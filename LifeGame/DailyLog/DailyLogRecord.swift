import Foundation
import SwiftData

@Model
final class DailyLogRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var payload: Data   // DailyLogEntry 的 JSON Data

    init(id: UUID, date: Date, payload: Data) {
        self.id = id
        self.date = date
        self.payload = payload
    }

    // 既有：entry -> record
    convenience init(entry: DailyLogEntry) {
        self.init(id: entry.id, date: entry.date, payload: Self.encodeEntry(entry))
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
        id = entry.id
        date = entry.date
        payload = Self.encodeEntry(entry)
    }

    // ✅ 相容層：外部如果寫 record.update(entry: xxx)
    func update(entry: DailyLogEntry) {
        update(from: entry)
    }

    // MARK: - Nonisolated helpers（避免 Swift 6 concurrency 警告）

    private nonisolated static func encodeEntry(_ entry: DailyLogEntry) -> Data {
        (try? JSONEncoder().encode(entry)) ?? Data()
    }

    private nonisolated static func decodeEntry(from data: Data) -> DailyLogEntry? {
        try? JSONDecoder().decode(DailyLogEntry.self, from: data)
    }
}
