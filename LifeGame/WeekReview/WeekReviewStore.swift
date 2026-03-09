import Foundation
import Combine
import SwiftUI
import Combine

final class WeekReviewStore: ObservableObject {
    
    private let storageKey = "weekReview.data"
    @Published private(set) var items: [String: WeekReview] = [:]
    
    init() { loadFromDisk() }
    
    func review(for weekKey: String) -> WeekReview? {
        items[weekKey]
    }
    
    func upsert(_ r: WeekReview) {
        var v = r
        v.updatedAt = Date()
        items[v.weekKey] = v
        saveToDisk()
        objectWillChange.send()
    }
    
    func currentWeekKey(date: Date = Date()) -> String {
        let cal = Calendar.current
        let w = cal.component(.weekOfYear, from: date)
        let y = cal.component(.yearForWeekOfYear, from: date)
        return String(format: "%04d-W%02d", y, w)
    }
    
    func lastWeekKey(date: Date = Date()) -> String {
        let cal = Calendar.current
        let d = cal.date(byAdding: .day, value: -7, to: date) ?? date
        return currentWeekKey(date: d)
    }
    
    private func saveToDisk() {
        StorageManager.save(items, forKey: storageKey)
    }
    
    private func loadFromDisk() {
        if let saved: [String: WeekReview] = StorageManager.load([String: WeekReview].self, forKey: storageKey) {
            items = saved
        }
    }
}
