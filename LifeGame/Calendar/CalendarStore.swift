import Foundation
import Combine
import EventKit
import SwiftUI

@MainActor
final class CalendarStore: ObservableObject {
    private static let storageKey = "calendar_events_v1"
    
    @Published var events: [CalendarEvent] = [] {
        didSet { save() }
    }
    
    private let eventStore = EKEventStore()
    
    init() {
        load()
    }
    
    func requestAccessIfNeeded() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            debugLog("行事曆授權失敗：\(error)")
            return false
        }
    }
    
    func add(title: String, start: Date, end: Date, colorHex: String = "33A6B8") async {
        var appleEventIdentifier: String? = nil
        
        let granted = await requestAccessIfNeeded()
        
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
