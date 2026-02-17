// File: History/HistoryStore.swift
import SwiftUI
import Foundation

final class HistoryStore: ObservableObject {
    @Published var records: [String: DayRecord] = [:]
    private let key = "history_records_v1"
    
    init() { load() }
    
    func upsert(record: DayRecord) {
        records[record.dateKey] = record
        save()
    }
    
    func record(for date: Date) -> DayRecord? {
        records[dateKeyString(date)]
    }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: DayRecord].self, from: data)
        else { return }
        records = decoded
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    func records(in month: Date) -> [DayRecord] {
        let cal = calendarTW()
        guard let interval = cal.dateInterval(of: .month, for: month) else { return [] }
        
        return records.values
            .filter {
                if let d = parseDateKey($0.dateKey) {
                    return d >= interval.start && d < interval.end
                }
                return false
            }
            .sorted { $0.dateKey < $1.dateKey }
    }
}
