import Foundation
import SwiftUI
import Combine

@MainActor
final class WeeklyScheduleStore: ObservableObject {
    private let storageKey = "weekly_schedule_v1"
    private let lastLoadedDateKey = "schedule_last_loaded_date"

    @Published var scheduleByDay: [String: [RingItem]] = [:]
    private var hasLoaded = false
    private var syncHelper: StoreSyncHelper?

    init() {
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        if let saved: [String: [RingItem]] = StorageManager.load([String: [RingItem]].self, forKey: storageKey) {
            scheduleByDay = saved
        }
    }

    // MARK: - Cross-device Sync

    func reloadFromStorage() {
        if let saved: [String: [RingItem]] = StorageManager.load([String: [RingItem]].self, forKey: storageKey) {
            scheduleByDay = saved
        }
        hasLoaded = true
    }

    // MARK: - CRUD

    func items(for weekday: Weekday) -> [RingItem] {
        loadIfNeeded()
        return scheduleByDay[String(weekday.rawValue)] ?? []
    }

    func addItem(_ item: RingItem, for weekday: Weekday) {
        loadIfNeeded()
        let key = String(weekday.rawValue)
        var list = scheduleByDay[key] ?? []
        list.append(item)
        list.sort { $0.startMinute < $1.startMinute }
        scheduleByDay[key] = list
        save()
    }

    func updateItem(_ item: RingItem, for weekday: Weekday) {
        loadIfNeeded()
        let key = String(weekday.rawValue)
        var list = scheduleByDay[key] ?? []
        guard let idx = list.firstIndex(where: { $0.id == item.id }) else { return }
        list[idx] = item
        list.sort { $0.startMinute < $1.startMinute }
        scheduleByDay[key] = list
        save()
    }

    func removeItem(id: UUID, for weekday: Weekday) {
        loadIfNeeded()
        let key = String(weekday.rawValue)
        var list = scheduleByDay[key] ?? []
        list.removeAll { $0.id == id }
        scheduleByDay[key] = list
        save()
    }

    func removeItems(at offsets: IndexSet, for weekday: Weekday) {
        loadIfNeeded()
        let key = String(weekday.rawValue)
        var list = scheduleByDay[key] ?? []
        list.remove(atOffsets: offsets)
        scheduleByDay[key] = list
        save()
    }

    // MARK: - 自動載入課表到 Plan

    @discardableResult
    func applyScheduleIfNeeded(to plan: inout TomorrowRingPlan) -> Bool {
        loadIfNeeded()
        let todayKey = dateKeyString()
        let lastLoaded: String? = StorageManager.load(String.self, forKey: lastLoadedDateKey)

        guard lastLoaded != todayKey else { return false }

        plan.items.removeAll { $0.isFromSchedule }

        let today = Weekday.today
        let templateItems = items(for: today)

        for template in templateItems {
            var newItem = template
            newItem.id = UUID()
            newItem.isFromSchedule = true
            plan.items.append(newItem)
        }

        plan.items.sort { $0.startMinute < $1.startMinute }
        StorageManager.save(todayKey, forKey: lastLoadedDateKey)

        return true
    }

    // MARK: - Persistence

    private func save() {
        StorageManager.save(scheduleByDay, forKey: storageKey)
    }

    private func dateKeyString(_ date: Date = Date()) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }
}
