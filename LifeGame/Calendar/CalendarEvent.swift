import Foundation

struct CalendarEvent: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var start: Date
    var end: Date
    var colorHex: String = "33A6B8"

    // Apple 行事曆事件的 ID
    var appleEventIdentifier: String? = nil

    init(
        id: UUID = UUID(),
        title: String,
        start: Date,
        end: Date,
        colorHex: String = "33A6B8",
        appleEventIdentifier: String? = nil
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.colorHex = colorHex
        self.appleEventIdentifier = appleEventIdentifier
    }
}
