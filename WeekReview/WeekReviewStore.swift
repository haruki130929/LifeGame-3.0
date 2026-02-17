import Foundation
import SwiftUI

final class WeekReviewStore: ObservableObject {
    
    @AppStorage("weekReview.data") private var data: Data = Data()
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
        do { data = try JSONEncoder().encode(items) }
        catch { print("weekReview save failed:", error) }
    }
    
    private func loadFromDisk() {
        guard !data.isEmpty else { return }
        do { items = try JSONDecoder().decode([String: WeekReview].self, from: data) }
        catch { print("weekReview load failed:", error) }
    }
}
