import Foundation

extension Calendar {
    
    func startOfMonth(_ date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
    
    func formatMonthYear(_ date: Date) -> String {
        let df = DateFormatter()
        df.calendar = self
        df.locale = locale
        df.timeZone = timeZone
        df.dateFormat = "M月 yyyy"
        return df.string(from: date)
    }
    
    func shortWeekdaySymbol(for date: Date) -> String {
        // weekday: 1..7
        let w = component(.weekday, from: date)
        let symbols = shortWeekdaySymbols // ["週日","週一"...]（依 locale）
        let idx = max(0, min(symbols.count - 1, w - 1))
        return symbols[idx]
    }
    
    func weekStart(for anchor: Date) -> Date {
        // 會尊重 firstWeekday（由 settings.calendar 設）
        guard let interval = dateInterval(of: .weekOfYear, for: anchor) else { return anchor }
        return interval.start
    }
    
    func weekDays(for anchor: Date) -> [Date] {
        let start = weekStart(for: anchor)
        return (0..<7).compactMap { date(byAdding: .day, value: $0, to: start) }
    }
    
    func weeksCoveringMonth(_ monthAnchor: Date) -> [[Date]] {
        let monthStart = startOfMonth(monthAnchor)
        guard let monthInterval = dateInterval(of: .month, for: monthStart) else { return [] }
        
        // 取「包含月初那一週」的週起點
        let firstWeekStart = weekStart(for: monthStart)
        
        // 取「包含月底那一週」的週終點（用 monthInterval.end - 1day 避免落在下個月第一天）
        let lastDay = date(byAdding: .day, value: -1, to: monthInterval.end) ?? monthInterval.end
        guard let lastWeekInterval = dateInterval(of: .weekOfYear, for: lastDay) else { return [] }
        let end = lastWeekInterval.end
        
        var weeks: [[Date]] = []
        var cursor = firstWeekStart
        
        while cursor < end {
            let oneWeek = (0..<7).compactMap { date(byAdding: .day, value: $0, to: cursor) }
            weeks.append(oneWeek)
            cursor = date(byAdding: .day, value: 7, to: cursor) ?? end
        }
        
        return weeks
    }
    
    func isInSameMonth(_ date: Date, as monthAnchor: Date) -> Bool {
        let a = dateComponents([.year, .month], from: date)
        let b = dateComponents([.year, .month], from: monthAnchor)
        return a.year == b.year && a.month == b.month
    }
    
    func dayTimeString(_ date: Date) -> String {
        let df = DateFormatter()
        df.calendar = self
        df.locale = locale
        df.timeZone = timeZone
        df.dateFormat = "HH:mm"
        return df.string(from: date)
    }
}
