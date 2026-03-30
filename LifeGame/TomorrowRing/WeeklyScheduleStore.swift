import Foundation
import SwiftUI
import Combine

@MainActor
final class WeeklyScheduleStore: ObservableObject {
    private let storageKey = "weekly_schedule_v1"
    private let lastLoadedDateKey = "schedule_last_loaded_date"

    @Published var schedule: WeeklySchedule = WeeklySchedule()

    init() {
        if let saved: WeeklySchedule = StorageManager.load(WeeklySchedule.self, forKey: storageKey) {
            schedule = saved
        }
    }

    // MARK: - CRUD

    func items(for weekday: Weekday) -> [RingItem] {
        schedule.items(for: weekday)
    }

    func addItem(_ item: RingItem, for weekday: Weekday) {
        var items = schedule.items(for: weekday)
        items.append(item)
        items.sort { $0.startMinute < $1.startMinute }
        schedule.setItems(items, for: weekday)
        save()
    }

    func updateItem(_ item: RingItem, for weekday: Weekday) {
        var items = schedule.items(for: weekday)
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx] = item
        items.sort { $0.startMinute < $1.startMinute }
        schedule.setItems(items, for: weekday)
        save()
    }

    func removeItem(id: UUID, for weekday: Weekday) {
        var items = schedule.items(for: weekday)
        items.removeAll { $0.id == id }
        schedule.setItems(items, for: weekday)
        save()
    }

    func removeItems(at offsets: IndexSet, for weekday: Weekday) {
        var items = schedule.items(for: weekday)
        items.remove(atOffsets: offsets)
        schedule.setItems(items, for: weekday)
        save()
    }

    // MARK: - 自動載入課表到 Plan

    /// 每天首次呼叫時，將今天的課表載入到 plan 中
    /// - Returns: true 表示有載入新課表
    @discardableResult
    func applyScheduleIfNeeded(to plan: inout TomorrowRingPlan) -> Bool {
        let todayKey = dateKeyString()
        let lastLoaded: String? = StorageManager.load(String.self, forKey: lastLoadedDateKey)

        guard lastLoaded != todayKey else { return false }

        // 移除舊的課表項目
        plan.items.removeAll { $0.isFromSchedule }

        // 載入今天的課表（產生新 UUID）
        let today = Weekday.today
        let templateItems = schedule.items(for: today)

        for template in templateItems {
            var newItem = template
            newItem.id = UUID()  // 新 UUID，避免 HP/FP 扣除衝突
            newItem.isFromSchedule = true
            plan.items.append(newItem)
        }

        plan.items.sort { $0.startMinute < $1.startMinute }

        // 記錄今天已載入
        StorageManager.save(todayKey, forKey: lastLoadedDateKey)

        return true
    }

    // MARK: - Persistence

    private func save() {
        StorageManager.save(schedule, forKey: storageKey)
    }

    private func dateKeyString(_ date: Date = Date()) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }
}
