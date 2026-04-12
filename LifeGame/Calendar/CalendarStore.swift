import Foundation
import Combine
import EventKit
import SwiftUI

@MainActor
final class CalendarStore: ObservableObject {
    private static let storageKey = "calendar_events_v1"
    
    @Published var events: [CalendarEvent] = [] {
        didSet { if !isReloading { save() } }
    }

    private let eventStore = EKEventStore()
    private var syncHelper: StoreSyncHelper?
    private var isReloading = false
    
    init() {
        load()
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    func reloadFromStorage() {
        isReloading = true
        defer { isReloading = false }
        if let saved: [CalendarEvent] = StorageManager.load([CalendarEvent].self, forKey: Self.storageKey) {
            events = saved
        }
    }
    
    func requestAccessIfNeeded() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            debugLog("行事曆授權失敗：\(error)")
            return false
        }
    }
    
    func add(title: String, start: Date, end: Date, colorHex: String = "33A6B8", isWeeklyRecurring: Bool = false) async {
        let granted = await requestAccessIfNeeded()

        if isWeeklyRecurring {
            // 建立 12 週的週期事件
            let groupId = UUID()
            let cal = Calendar.current
            let duration = end.timeIntervalSince(start)

            // Apple 行事曆：建立週期性事件
            var appleEventIdentifier: String? = nil
            if granted {
                do {
                    let ekEvent = EKEvent(eventStore: eventStore)
                    ekEvent.title = title
                    ekEvent.startDate = start
                    ekEvent.endDate = end
                    ekEvent.calendar = eventStore.defaultCalendarForNewEvents
                    ekEvent.recurrenceRules = [EKRecurrenceRule(
                        recurrenceWith: .weekly,
                        interval: 1,
                        end: EKRecurrenceEnd(occurrenceCount: 12)
                    )]
                    try eventStore.save(ekEvent, span: .thisEvent)
                    appleEventIdentifier = ekEvent.eventIdentifier
                } catch {
                    debugLog("寫入 Apple 週期行事曆失敗：\(error)")
                }
            }

            // App 內部：建立 12 筆個別事件
            for week in 0..<12 {
                let weekStart = cal.date(byAdding: .weekOfYear, value: week, to: start)!
                let weekEnd = weekStart.addingTimeInterval(duration)
                let e = CalendarEvent(
                    title: title,
                    start: weekStart,
                    end: weekEnd,
                    colorHex: colorHex,
                    isWeeklyRecurring: true,
                    recurringGroupId: groupId,
                    appleEventIdentifier: week == 0 ? appleEventIdentifier : nil
                )
                events.insert(e, at: 0)
            }
        } else {
            // 單次事件
            var appleEventIdentifier: String? = nil
            if granted {
                do {
                    let ekEvent = EKEvent(eventStore: eventStore)
                    ekEvent.title = title
                    ekEvent.startDate = start
                    ekEvent.endDate = end
                    ekEvent.calendar = eventStore.defaultCalendarForNewEvents
                    try eventStore.save(ekEvent, span: .thisEvent)
                    appleEventIdentifier = ekEvent.eventIdentifier
                } catch {
                    debugLog("寫入 Apple 行事曆失敗：\(error)")
                }
            }

            let e = CalendarEvent(
                title: title,
                start: start,
                end: end,
                colorHex: colorHex,
                appleEventIdentifier: appleEventIdentifier
            )
            events.insert(e, at: 0)
        }
    }

    /// 刪除整組週期事件
    func deleteRecurringGroup(_ groupId: UUID) {
        let groupEvents = events.filter { $0.recurringGroupId == groupId }
        for item in groupEvents {
            if let appleID = item.appleEventIdentifier,
               let ekEvent = eventStore.event(withIdentifier: appleID) {
                do {
                    try eventStore.remove(ekEvent, span: .futureEvents)
                } catch {
                    debugLog("刪除 Apple 週期事件失敗：\(error)")
                }
            }
        }
        events.removeAll { $0.recurringGroupId == groupId }
    }
    
    func delete(at offsets: IndexSet) {
        let deletingEvents = offsets.map { events[$0] }
        
        for item in deletingEvents {
            if let appleID = item.appleEventIdentifier,
               let ekEvent = eventStore.event(withIdentifier: appleID) {
                do {
                    try eventStore.remove(ekEvent, span: .thisEvent)
                } catch {
                    debugLog("刪除 Apple 行事曆事件失敗：\(error)")
                }
            }
        }
        
        events.remove(atOffsets: offsets)
    }
    
    func events(on day: Date, calendar: Calendar) -> [CalendarEvent] {
        events
            .filter { calendar.isDate($0.start, inSameDayAs: day) }
            .sorted { $0.start < $1.start }
    }
    
    func events(inWeekContaining anchor: Date, calendar: Calendar) -> [CalendarEvent] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: anchor) else { return [] }
        
        return events
            .filter { $0.start >= interval.start && $0.start < interval.end }
            .sorted { $0.start < $1.start }
    }
    
    func update(_ event: CalendarEvent) {
        guard let idx = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[idx] = event
    }
    
    private func save() {
        StorageManager.save(events, forKey: Self.storageKey)
    }
    
    private func load() {
        if let saved: [CalendarEvent] = StorageManager.load([CalendarEvent].self, forKey: Self.storageKey) {
            events = saved
        }
    }
}
