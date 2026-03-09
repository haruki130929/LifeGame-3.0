// File: Helpers/DateHelpers.swift
import Foundation

func calendarTW() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.locale = Locale(identifier: "zh_Hant_TW")
    cal.timeZone = TimeZone(identifier: "Asia/Taipei")!
    cal.firstWeekday = 1 // Sunday
    return cal
}

func parseDateKey(_ key: String) -> Date? {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.locale = Locale(identifier: "zh_Hant_TW")
    f.timeZone = TimeZone(identifier: "Asia/Taipei")
    f.dateFormat = "yyyy-MM-dd"
    return f.date(from: key)
}

func monthTitle(_ date: Date) -> String {
    let f = DateFormatter()
    f.calendar = calendarTW()
    f.locale = Locale(identifier: "zh_Hant_TW")
    f.timeZone = TimeZone(identifier: "Asia/Taipei")
    f.dateFormat = "yyyy年 M月"
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

func dateKeyString(_ date: Date) -> String {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.locale = Locale(identifier: "zh_Hant_TW")
    f.timeZone = TimeZone(identifier: "Asia/Taipei")
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
}

func medianOf3(_ a: Int, _ b: Int, _ c: Int) -> Int {
    let s = [a, b, c].sorted()
    return s[1]
}
