import Foundation

struct CalendarEvent: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var start: Date
    var end: Date
    
    init(id: UUID = UUID(), title: String, start: Date, end: Date) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
    }
}
