import Foundation

@MainActor
final class CalendarStore: ObservableObject {
    private static let storageKey = "calendar_events_v1"
    
    @Published var events: [CalendarEvent] = [] {
        didSet { save() }
    }
    
    init() { load() }
    
    func add(title: String, start: Date, end: Date) {
        let e = CalendarEvent(title: title, start: start, end: end)
        events.insert(e, at: 0)
    }
    
    func delete(at offsets: IndexSet) {
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
        do {
            let data = try JSONEncoder().encode(events)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            print("CalendarStore save failed:", error)
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return }
        do {
            events = try JSONDecoder().decode([CalendarEvent].self, from: data)
        } catch {
            print("CalendarStore load failed:", error)
        }
    }
}
