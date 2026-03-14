import SwiftUI

struct CalendarCard: View {
    let size: CardSize
    let monthDate: Date
    let ranges: [CalendarRange]
    let onPrevMonth: () -> Void
    let onNextMonth: () -> Void
    let urgentImportantTasks: [UrgentImportantTask]

    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var calendarSettings: CalendarSettingsStore
    @State private var selected: Date = Date()

    private var cal: Calendar { calendarSettings.calendar }
    private let rowGap: CGFloat = 6
    private let barInsetX: CGFloat = 2
    
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        
        VStack(alignment: .leading, spacing: 10) {
            header
            weekdayRow
            monthGrid
            
            // ✅ medium / large 都顯示 footer（small 不顯示）
            if size != .small {
                Divider().opacity(0.35)
                footer
            }
        }
        .padding(14)
        .background {
            if theme.isDark {
                shape.fill(.thinMaterial)
            } else {
                shape.fill(Color.white)
            }
        }
        .overlay(shape.strokeBorder(
            theme.isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.10),
            lineWidth: 1))
        .shadow(
            color: theme.isDark ? .clear : .black.opacity(0.08),
            radius: 8, x: 0, y: 3)
        .contentShape(shape)
        .clipShape(shape)
    }
    
    // MARK: - Header
    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("\(monthNumber)")
                .font(.system(size: size == .large ? 22 : 18,
                              weight: .semibold,
                              design: .rounded))
            
            Rectangle()
                .fill(.secondary.opacity(0.5))
                .frame(width: 1, height: size == .large ? 22 : 18)
            
            Text("\(selectedDayNumber)")
                .font(.system(size: size == .large ? 14 : 12, weight: .semibold))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack(spacing: 10) {
                Button(action: onPrevMonth) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                
                Button(action: onNextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Weekday row
    private var weekdayRow: some View {
        let symbols = weekdaySymbols
        return HStack(spacing: 0) {
            ForEach(symbols, id: \.self) { s in
                Text(s)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Grid（底：行程條 / 中：日期 / 上：today 紅圈）
    private var monthGrid: some View {
        let days = monthCells
        let cellH = calendarDayCellHeight
        
        let rows = max(1, days.count / 7)
        let gridH = cellH * CGFloat(rows) + rowGap * CGFloat(rows - 1)
        
        return ZStack(alignment: .topLeading) {
            rangeBarsOverlay(cellHeight: cellH)
                .frame(height: gridH)
                .allowsHitTesting(false)
            
            LazyVGrid(
                columns: Array(repeating: .init(.flexible(), spacing: 0), count: 7),
                spacing: rowGap
            ) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, cell in
                    dayCellView(cell)
                        .frame(height: cellH)
                }
            }
        }
        .frame(height: gridH)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    
    private func rangeBarsOverlay(cellHeight: CGFloat) -> some View {
        GeometryReader { geo in
            let totalW = geo.size.width
            let colW = totalW / 7.0
            let gap = rowGap
            
            ZStack(alignment: .topLeading) {
                ForEach(ranges.compactMap(clippedToMonth)) { r in
                    let segs = rangeSegments(range: r)
                    
                    ForEach(Array(segs.enumerated()), id: \.element.id) { idx, seg in
                        let isFirst = (idx == 0)
                        let isLast  = (idx == segs.count - 1)
                        
                        let x1 = CGFloat(seg.startCol) * colW + barInsetX
                        let x2 = CGFloat(seg.endCol + 1) * colW - barInsetX
                        
                        let barH = min(cellHeight * 0.9, cellHeight - 2)
                        let y = CGFloat(seg.row) * (cellHeight + gap) + cellHeight / 2
                        
                        RangeBarShape(isStart: isFirst, isEnd: isLast, radius: barH / 2)
                            .fill(r.color)
                            .frame(width: x2 - x1, height: barH)
                            .position(x: (x1 + x2) / 2, y: y)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func dayCellView(_ cell: CalendarDayCell) -> some View {
        Group {
            if let date = cell.date {
                Button {
                    selected = date
                } label: {
                    ZStack {
                        let isToday = cal.isDateInToday(date)
                        let isSelected = cal.isDate(date, inSameDayAs: selected)
                        
                        // selected 淡圈（非今天）
                        if isSelected && !isToday {
                            Circle()
                                .fill(theme.isDark
                                    ? Color.white.opacity(0.14)
                                    : Color.black.opacity(0.08))
                                .frame(width: dayCircleSize, height: dayCircleSize)
                                .zIndex(1)
                        }
                        
                        // 今天紅圈
                        if isToday {
                            Circle()
                                .fill(Color.red)
                                .frame(width: dayCircleSize * 0.78,
                                       height: dayCircleSize * 0.78)
                                .zIndex(2)
                        }
                        
                        // 日期文字
                        Text("\(cal.component(.day, from: date))")
                            .font(.system(size: dayFontSize, weight: .semibold))
                            .foregroundStyle(
                                isToday ? .white : (cell.isInCurrentMonth ? .primary : .secondary)
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .zIndex(3)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Color.clear
            }
        }
    }
    
    // MARK: - Footer（依 size 自動選擇）
    private var footer: some View {
        switch size {
        case .large:
            return AnyView(largeFooter)
        case .medium:
            return AnyView(mediumFooter)
        case .small:
            return AnyView(EmptyView())
        }
    }
    
    private var largeFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("重要又緊急")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            let items = Array(urgentImportantTasks.prefix(3))
            
            if items.isEmpty {
                Text("目前沒有")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(items) { t in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red.opacity(0.9))
                                .frame(width: 6, height: 6)
                            
                            Text(t.title)
                                .font(.footnote)
                                .lineLimit(1)
                            
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .padding(.top, 4)
    }
    
    private var mediumFooter: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("重要又緊急")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            let items = Array(urgentImportantTasks.prefix(2)) // ✅ medium 少一點，避免撐高
            
            if items.isEmpty {
                Text("目前沒有")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(items) { t in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red.opacity(0.9))
                                .frame(width: 5, height: 5)
                            
                            Text(t.title)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .padding(.top, 2)
    }
    
    // MARK: - Range segmentation
    private func rangeSegments(range: CalendarRange) -> [RangeSegment] {
        guard
            let startIndex = indexOfDate(range.start),
            let endIndex   = indexOfDate(range.end)
        else { return [] }
        
        let s = min(startIndex, endIndex)
        let e = max(startIndex, endIndex)
        
        let startRow = s / 7
        let endRow = e / 7
        
        if startRow == endRow {
            return [RangeSegment(row: startRow, startCol: s % 7, endCol: e % 7)]
        }
        
        var segs: [RangeSegment] = []
        segs.append(RangeSegment(row: startRow, startCol: s % 7, endCol: 6))
        
        if endRow - startRow > 1 {
            for row in (startRow + 1)...(endRow - 1) {
                segs.append(RangeSegment(row: row, startCol: 0, endCol: 6))
            }
        }
        
        segs.append(RangeSegment(row: endRow, startCol: 0, endCol: e % 7))
        return segs
    }
    
    private func indexOfDate(_ date: Date) -> Int? {
        for (i, cell) in monthCells.enumerated() {
            guard let d = cell.date else { continue }
            if cal.isDate(d, inSameDayAs: date) { return i }
        }
        return nil
    }
    
    // MARK: - Derived
    private var monthNumber: Int { cal.component(.month, from: monthDate) }
    
    private var monthStart: Date {
        cal.date(from: cal.dateComponents([.year, .month], from: monthDate))!
    }
    
    private var monthEnd: Date {
        cal.date(byAdding: DateComponents(month: 1), to: monthStart)!
    }
    
    private func clippedToMonth(_ r: CalendarRange) -> CalendarRange? {
        let s = max(r.start, monthStart)
        let e = min(r.end, monthEnd)
        guard s < e else { return nil }
        return CalendarRange(start: s, end: e, color: r.color)
    }
    
    private var selectedDayNumber: Int { cal.component(.day, from: selected) }
    
    /// 中文星期符號，依 firstWeekday 設定排列
    private var weekdaySymbols: [String] {
        cal.chineseWeekdaySymbols
    }
    
    /// Month cells（補齊到滿週數）
    private var monthCells: [CalendarDayCell] {
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: monthDate)) ?? monthDate
        let dayRange = cal.range(of: .day, in: .month, for: startOfMonth) ?? 1..<31
        
        let weekday = cal.component(.weekday, from: startOfMonth) // Sun=1 ... Sat=7
        let leading = (weekday - cal.firstWeekday + 7) % 7
        
        var cells: [CalendarDayCell] = []
        cells.reserveCapacity(42)
        
        for _ in 0..<leading {
            cells.append(CalendarDayCell(date: nil, isInCurrentMonth: false))
        }
        
        for day in dayRange {
            if let d = cal.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                cells.append(CalendarDayCell(date: d, isInCurrentMonth: true))
            }
        }
        
        let remainder = cells.count % 7
        if remainder != 0 {
            for _ in 0..<(7 - remainder) {
                cells.append(CalendarDayCell(date: nil, isInCurrentMonth: false))
            }
        }
        
        return cells
    }
    
    // MARK: - Sizing
    private var calendarDayCellHeight: CGFloat {
        switch size {
        case .small:  return 20
        case .medium: return 24
        case .large:  return 28
        }
    }
    
    private var dayCircleSize: CGFloat {
        switch size {
        case .small:  return 20
        case .medium: return 24
        case .large:  return 28
        }
    }
    
    private var dayFontSize: CGFloat {
        switch size {
        case .small:  return 12
        case .medium: return 14
        case .large:  return 14
        }
    }
}

// MARK: - Local Models（放同檔也 OK）
private struct CalendarDayCell {
    let date: Date?
    let isInCurrentMonth: Bool
}

struct CalendarRange: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let color: Color
}

struct RangeSegment: Identifiable {
    let id = UUID()
    let row: Int
    let startCol: Int
    let endCol: Int
}

struct CalendarRangeProvider {
    let cal = Calendar.current
    
    func ranges(from events: [CalendarEvent], in monthDate: Date) -> [CalendarRange] {
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: monthDate))!
        let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart)!
        
        return events.compactMap { e in
            let rawStart = min(e.start, e.end)
            let rawEnd   = max(e.start, e.end)
            
            let s = max(rawStart, monthStart)
            let e = min(rawEnd, monthEnd)
            guard s < e else { return nil }
            
            return CalendarRange(start: s, end: e, color: Color.cyan.opacity(0.70))
        }
    }
}

private struct RangeBarShape: Shape {
    let isStart: Bool
    let isEnd: Bool
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let tl: CGFloat = isStart ? radius : 0
        let bl: CGFloat = isStart ? radius : 0
        let tr: CGFloat = isEnd ? radius : 0
        let br: CGFloat = isEnd ? radius : 0
        
        var p = Path()
        p.addRoundedRect(in: rect,
                         topLeftRadius: tl,
                         topRightRadius: tr,
                         bottomLeftRadius: bl,
                         bottomRightRadius: br)
        return p
    }
}

private extension Path {
    mutating func addRoundedRect(in rect: CGRect,
                                 topLeftRadius: CGFloat,
                                 topRightRadius: CGFloat,
                                 bottomLeftRadius: CGFloat,
                                 bottomRightRadius: CGFloat) {
        let w = rect.width, h = rect.height
        let x = rect.minX, y = rect.minY
        
        let tl = min(min(topLeftRadius, h/2), w/2)
        let tr = min(min(topRightRadius, h/2), w/2)
        let bl = min(min(bottomLeftRadius, h/2), w/2)
        let br = min(min(bottomRightRadius, h/2), w/2)
        
        move(to: CGPoint(x: x + tl, y: y))
        addLine(to: CGPoint(x: x + w - tr, y: y))
        addArc(center: CGPoint(x: x + w - tr, y: y + tr),
               radius: tr,
               startAngle: .degrees(-90),
               endAngle: .degrees(0),
               clockwise: false)
        
        addLine(to: CGPoint(x: x + w, y: y + h - br))
        addArc(center: CGPoint(x: x + w - br, y: y + h - br),
               radius: br,
               startAngle: .degrees(0),
               endAngle: .degrees(90),
               clockwise: false)
        
        addLine(to: CGPoint(x: x + bl, y: y + h))
        addArc(center: CGPoint(x: x + bl, y: y + h - bl),
               radius: bl,
               startAngle: .degrees(90),
               endAngle: .degrees(180),
               clockwise: false)
        
        addLine(to: CGPoint(x: x, y: y + tl))
        addArc(center: CGPoint(x: x + tl, y: y + tl),
               radius: tl,
               startAngle: .degrees(180),
               endAngle: .degrees(270),
               clockwise: false)
        
        closeSubpath()
    }
}

struct UrgentImportantTask: Identifiable {
    let id = UUID()
    let title: String
}
