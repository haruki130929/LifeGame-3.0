import Foundation
import SwiftUI

@MainActor
final class Key3Store: ObservableObject {
    
    @AppStorage("Key3.plansData") private var plansData: Data = Data()
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
    
    // MARK: - Persistence
    private func save() {
        plansData = (try? JSONEncoder().encode(plans)) ?? Data()
    }
    
    private func load() {
        guard let decoded = try? JSONDecoder().decode([String: Key3Plan].self, from: plansData)
        else { return }
        plans = decoded
    }
    
    func dateKeyString(_ date: Date) -> String {
        let d = Calendar.current.startOfDay(for: date)
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }
}
