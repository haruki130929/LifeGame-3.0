import SwiftUI

struct MonthScrollView: View {
    @ObservedObject var store: CalendarStore
    let calendar: Calendar
    @Binding var anchorDate: Date
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                let months = monthAnchors(around: anchorDate, count: 13) // 前後各 6 + 本月
                ForEach(months, id: \.self) { monthAnchor in
                    MonthSection(
                        store: store,
                        calendar: calendar,
                        monthAnchor: monthAnchor
                    )
                    .padding(.horizontal, 12)
                }
            }
            .padding(.vertical, 12)
        }
    }
    
    private func monthAnchors(around date: Date, count: Int) -> [Date] {
        let half = count / 2
        let base = calendar.startOfMonth(date)
        return (-half...half).compactMap {
            calendar.date(byAdding: .month, value: $0, to: base)
        }
    }
}

private struct MonthSection: View {
    @ObservedObject var store: CalendarStore
    let calendar: Calendar
    let monthAnchor: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(calendar.formatMonthYear(monthAnchor))
                .font(.headline)
            
            let weeks = calendar.weeksCoveringMonth(monthAnchor)
            ForEach(weeks.indices, id: \.self) { i in
                WeekRow(store: store, calendar: calendar, monthAnchor: monthAnchor, days: weeks[i])
                    .padding(.vertical, 6)
                
                if i != weeks.count - 1 { Divider() }
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct WeekRow: View {
    @ObservedObject var store: CalendarStore
    let calendar: Calendar
    let monthAnchor: Date
    let days: [Date] // 7天
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(days, id: \.self) { d in
                let inMonth = calendar.isInSameMonth(d, as: monthAnchor)
                let dots = min(store.events(on: d, calendar: calendar).count, 4)
                
                MonthDayCell(
                    calendar: calendar,
                    day: d,
                    isInCurrentMonth: inMonth,
                    dots: dots
                )
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct MonthDayCell: View {
    let calendar: Calendar
    let day: Date
    let isInCurrentMonth: Bool
    let dots: Int
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.headline)
                
                Text(calendar.shortWeekdaySymbol(for: day))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 4) {
                ForEach(0..<dots, id: \.self) { _ in
                    Circle().frame(width: 5, height: 5)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .opacity(isInCurrentMonth ? 1.0 : 0.35)
    }
}
