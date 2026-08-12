// File: Helpers/DateHelpers.swift
import Foundation

/// App 全域的月曆運算用曆法。
///
/// 曆法（gregorian）、時區（Asia/Taipei，決定「一天」的分界）與 firstWeekday 都是刻意寫死的
/// 商業邏輯，不隨語言變動。但 locale 只影響「星期／月份名稱怎麼顯示」，
/// 以前寫死 zh_Hant_TW，會讓英日介面的星期標題仍然是「日 一 二…」，所以改成跟隨使用者。
/// 日期運算本身不受 locale 影響（曆法與 firstWeekday 都已明確指定）。
func calendarTW() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.locale = .current
    cal.timeZone = TimeZone(identifier: "Asia/Taipei") ?? .current
    cal.firstWeekday = 1 // Sunday
    return cal
}

func parseDateKey(_ key: String) -> Date? {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    // 這是資料的 key，格式必須固定；用 en_US_POSIX 才不會被使用者的曆法／語言影響
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(identifier: "Asia/Taipei")
    f.dateFormat = "yyyy-MM-dd"
    return f.date(from: key)
}

func monthTitle(_ date: Date) -> String {
    let f = DateFormatter()
    f.calendar = calendarTW()
    f.locale = .current
    f.timeZone = TimeZone(identifier: "Asia/Taipei")
    f.setLocalizedDateFormatFromTemplate("yMMMM")
    return f.string(from: date)
}

func shiftMonth(_ date: Date, by delta: Int) -> Date {
    calendarTW().date(byAdding: .month, value: delta, to: date) ?? date
}

/// 做出「月曆格」：從該月第一天開始，補齊到週起始，並補到 6 週（42 格）
func makeCalendarDays(for month: Date, calendar: Calendar) -> [Date] {
    guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
    let firstDay = monthInterval.start
    
    let weekday = calendar.component(.weekday, from: firstDay)
    let leading = (weekday - calendar.firstWeekday + 7) % 7
    
    let start = calendar.date(byAdding: .day, value: -leading, to: firstDay) ?? firstDay
    
    return (0..<42).compactMap { i in
        calendar.date(byAdding: .day, value: i, to: start)
    }
}

/// 凌晨 4 點前算前一天（減 4 小時後取日期）
func dateKeyString(_ date: Date) -> String {
    let adjusted = date.addingTimeInterval(-4 * 3600) // 04:00 才算新的一天
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    // 這是資料的 key，格式必須固定；用 en_US_POSIX 才不會被使用者的曆法／語言影響
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(identifier: "Asia/Taipei")
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: adjusted)
}

func medianOf3(_ a: Int, _ b: Int, _ c: Int) -> Int {
    let s = [a, b, c].sorted()
    return s[1]
}
