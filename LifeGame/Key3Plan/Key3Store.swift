import Foundation
import Combine
import SwiftUI

@MainActor
final class Key3Store: ObservableObject {
    
    private let storageKey = "Key3.plansData"
    
    @Published private(set) var plans: [String: Key3Plan] = [:]
    
    init() { load() }
    
    func plan(for date: Date) -> Key3Plan? {
        plans[dateKeyString(date)]
    }
    
    func upsert(_ plan: Key3Plan) {
        var p = plan
        p.updatedAt = Date()
        plans[p.dateKey] = p
        save()
    }
    
    func setActive(date: Date, taskID: UUID?) {
        let key = dateKeyString(date)
        guard var p = plans[key] else { return }
        p.activeTaskID = taskID
        p.updatedAt = Date()
        plans[key] = p
        save()
    }
    
    // MARK: - Persistence (SwiftData via StorageManager)
    private func save() {
        StorageManager.save(plans, forKey: storageKey)
    }
    
    private func load() {
        if let decoded: [String: Key3Plan] = StorageManager.load([String: Key3Plan].self, forKey: storageKey) {
            plans = decoded
        }
    }
    
    func dateKeyString(_ date: Date) -> String {
        let d = Calendar.current.startOfDay(for: date)
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }
}
