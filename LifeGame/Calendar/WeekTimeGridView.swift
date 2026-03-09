import SwiftUI

struct WeekTimeGridView: View {
    @ObservedObject var store: CalendarStore
    let calendar: Calendar
    @Binding var anchorDate: Date
    
    private let hourHeight: CGFloat = 56
    private let dayColumnWidth: CGFloat = 160
    private let headerHeight: CGFloat = 44
    private let timeColumnWidth: CGFloat = 72
    
    var body: some View {
        let weekDays = calendar.weekDays(for: anchorDate)
        
        ScrollView([.vertical, .horizontal]) {
            HStack(spacing: 0) {
                timeColumn
                
                ForEach(weekDays, id: \.self) { day in
                    DayColumn(
                        store: store,
                        calendar: calendar,
                        day: day,
                        hourHeight: hourHeight,
                        headerHeight: headerHeight
                    )
                    .frame(width: dayColumnWidth)
                }
            }
        }
    }
    
    private var timeColumn: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: headerHeight)
            
            ForEach(0..<24, id: \.self) { h in
                VStack(alignment: .trailing, spacing: 0) {
                    Text(String(format: "%02d:00", h))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(height: hourHeight, alignment: .topTrailing)
                    
                    Divider()
                }
                .frame(width: timeColumnWidth)
                .padding(.trailing, 8)
            }
        }
    }
}

private struct DayColumn: View {
    @ObservedObject var store: CalendarStore
    let calendar: Calendar
    let day: Date
    let hourHeight: CGFloat
    let headerHeight: CGFloat
    
    var body: some View {
        let dayEvents = store.events(on: day, calendar: calendar)
        
        ZStack(alignment: .topLeading) {
            grid
            
            ForEach(dayEvents) { e in
                EventBlock(
                    title: e.title,
                    time: "\(calendar.dayTimeString(e.start))–\(calendar.dayTimeString(e.end))"
                )
                .frame(width: 140)
                .offset(x: 10, y: headerHeight + yOffset(for: e))
            }
        }
        .overlay(alignment: .top) {
            DayHeader(calendar: calendar, day: day)
                .background(.ultraThinMaterial)
        }
        .overlay(alignment: .leading) { Divider() }
        .overlay(alignment: .trailing) { Divider() }
    }
    
    private var grid: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: headerHeight)
            
            ForEach(0..<24, id: \.self) { _ in
                Rectangle()
                    .fill(.clear)
                    .frame(height: hourHeight)
                    .overlay(alignment: .bottom) { Divider() }
            }
        }
    }
    
    private func yOffset(for event: CalendarEvent) -> CGFloat {
        // 依「開始分鐘」定位，先做 MVP，但比只看小時精準
        let hour = calendar.component(.hour, from: event.start)
        let minute = calendar.component(.minute, from: event.start)
        let minutePart = CGFloat(minute) / 60.0
        return (CGFloat(hour) + minutePart) * hourHeight + 8
    }
}

private struct DayHeader: View {
    let calendar: Calendar
    let day: Date
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(calendar.component(.day, from: day))")
                .font(.headline)
            
            Text(calendar.shortWeekdaySymbol(for: day))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
    }
}

private struct EventBlock: View {
    let title: String
    let time: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .lineLimit(1)
            
            Text(time)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
