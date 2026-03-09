import Foundation

struct CalendarEvent: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var start: Date
    var end: Date
    
    // Apple 行事曆事件的 ID
    var appleEventIdentifier: String? = nil
    
    init(
        id: UUID = UUID(),
        title: String,
        start: Date,
        end: Date,
        appleEventIdentifier: String? = nil
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.appleEventIdentifier = appleEventIdentifier
    }
}
