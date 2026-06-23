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

    /// 是否由 Apple 行事曆匯入。true 才會在同步時跟著 Apple 顏色更新；
    /// 手動建立的事件保留使用者自選的顏色。（optional：舊資料缺這個 key 也能解碼）
    var isFromAppleCalendar: Bool? = nil

    init(
        id: UUID = UUID(),
        title: String,
        start: Date,
        end: Date,
        colorHex: String = "33A6B8",
        isWeeklyRecurring: Bool = false,
        recurringGroupId: UUID? = nil,
        appleEventIdentifier: String? = nil,
        isFromAppleCalendar: Bool? = nil
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.colorHex = colorHex
        self.isWeeklyRecurring = isWeeklyRecurring
        self.recurringGroupId = recurringGroupId
        self.appleEventIdentifier = appleEventIdentifier
        self.isFromAppleCalendar = isFromAppleCalendar
    }
}
