import Foundation

// MARK: - RecurringFrequency

enum RecurringFrequency: String, CaseIterable, Identifiable {
    case none = "不重複"
    case daily = "每天"
    case weekly = "每週"
    case biweekly = "每兩週"
    case monthly = "每月"

    var id: String { rawValue }
}

// MARK: - CalendarEvent

struct CalendarEvent: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var start: Date
    var end: Date
    var colorHex: String = "33A6B8"
    var isWeeklyRecurring: Bool = false
    var recurringGroupId: UUID? = nil  // 同一組週期事件共用的 ID

    // Apple 行事曆事件的 ID
    var appleEventIdentifier: String? = nil

    init(
        id: UUID = UUID(),
        title: String,
        start: Date,
        end: Date,
        colorHex: String = "33A6B8",
        isWeeklyRecurring: Bool = false,
        recurringGroupId: UUID? = nil,
        appleEventIdentifier: String? = nil
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.colorHex = colorHex
        self.isWeeklyRecurring = isWeeklyRecurring
        self.recurringGroupId = recurringGroupId
        self.appleEventIdentifier = appleEventIdentifier
    }
}
