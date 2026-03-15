// File: History/HistoryStore.swift
import SwiftUI
import Combine
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
        if let decoded: [String: DayRecord] = StorageManager.load([String: DayRecord].self, forKey: key) {
            records = decoded
        }
    }
    
    func save() {
        StorageManager.save(records, forKey: key)
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
