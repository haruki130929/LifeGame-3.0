import SwiftUI
import Foundation

struct MonthlyScoreCalendarCardLarge: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @EnvironmentObject private var theme: ThemeStore

    private let title: String
    private let icon: String

    init(title: String = String(localized: "本月結算"), icon: String = "calendar.badge.clock") {
        self.title = title
        self.icon = icon
    }

    // MARK: - UI State
    @State private var selectedRecord: DayRecord?
    @State private var monthOffset = 0

    private let cal = Calendar.current

    var body: some View {
        DashboardCardShell(title: title, icon: icon) {
            VStack(alignment: .leading, spacing: 12) {
                header

                LazyVGrid(columns: gridColumns, spacing: 6) {
                    weekdayHeaderRow
                    dayCellsGrid
                }
            }
            .sheet(item: $selectedRecord) { record in
                dayDetailSheet(record)
            }
        }
    }
}

// MARK: - Header
private extension MonthlyScoreCalendarCardLarge {
    var header: some View {
        HStack {
            Text(yearMonthString(for: selectedMonthBase))
                .font(.headline)

            Spacer()

            Button { monthOffset -= 1 } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("上一個月")

            Button { monthOffset += 1 } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("下一個月")
        }
    }

}

// MARK: - Grid
private extension MonthlyScoreCalendarCardLarge {
    var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    }

    var weekdayHeaderRow: some View {
        ForEach(weekdaySymbols, id: \.self) { w in
            Text(w)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }

    var dayCellsGrid: some View {
        ForEach(cells) { cell in
            cellView(cell)
        }
    }

    func cellView(_ cell: MSDayCell) -> some View {
        Group {
            if let date = cell.date {
                let record = historyStore.record(for: date)

                dayLabel(date: date, record: record)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let record {
                            selectedRecord = record
                        }
                    }
            } else {
                Color.clear.frame(height: 28)
            }
        }
    }
}

// MARK: - Day Detail Sheet (Read-Only)
private extension MonthlyScoreCalendarCardLarge {
    func dayDetailSheet(_ record: DayRecord) -> some View {
        NavigationStack {
            List {
                Section("日期") {
                    Text(record.dateKey)
                }

                Section("狀態值") {
                    HStack {
                        Label("HP", systemImage: "heart.fill")
                            .foregroundStyle(.red)
                        Spacer()
                        Text("\(record.hp)")
                            .font(.title3.bold())
                    }

                    HStack {
                        Label("FP", systemImage: "brain.fill")
                            .foregroundStyle(.blue)
                        Spacer()
                        Text("\(record.fp)")
                            .font(.title3.bold())
                    }

                    HStack {
                        Label("MP", systemImage: "flame.fill")
                            .foregroundStyle(.orange)
                        Spacer()
                        Text("\(record.mp)")
                            .font(.title3.bold())
                    }
                }

                Section("結算") {
                    HStack {
                        Text("中位數")
                        Spacer()
                        Text("\(record.median)")
                            .font(.title3.bold())
                    }

                    HStack {
                        Text("難度")
                        Spacer()
                        Text(record.difficulty.title)
                            .foregroundStyle(record.difficulty.color)
                            .font(.title3.bold())
                    }

                    HStack {
                        Text("分數")
                        Spacer()
                        Text("\(record.score)")
                            .foregroundStyle(record.difficulty.color)
                            .font(.title3.bold())
                    }
                }
            }
            .navigationTitle("當日結算")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { selectedRecord = nil }
                }
            }
        }
    }
}

// MARK: - Calendar Data
private extension MonthlyScoreCalendarCardLarge {
    var selectedMonthBase: Date {
        cal.date(byAdding: .month, value: monthOffset, to: startOfMonth(Date())) ?? Date()
    }

    var weekdaySymbols: [String] {
        cal.localizedWeekdaySymbols
    }

    var cells: [MSDayCell] {
        let first = startOfMonth(selectedMonthBase)
        let days = daysInMonth(first)
        let leading = leadingEmptyCount(first)

        var result: [MSDayCell] = []
        result.append(contentsOf: Array(repeating: MSDayCell(date: nil), count: leading))

        for day in 1...days {
            let d = cal.date(from: DateComponents(
                year: cal.component(.year, from: first),
                month: cal.component(.month, from: first),
                day: day
            ))!
            result.append(MSDayCell(date: d))
        }

        while result.count % 7 != 0 {
            result.append(MSDayCell(date: nil))
        }

        return result
    }

    func startOfMonth(_ date: Date) -> Date {
        cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
    }

    func daysInMonth(_ firstDayOfMonth: Date) -> Int {
        cal.range(of: .day, in: .month, for: firstDayOfMonth)?.count ?? 30
    }

    func leadingEmptyCount(_ firstDayOfMonth: Date) -> Int {
        let weekday = cal.component(.weekday, from: firstDayOfMonth)
        let firstWeekday = cal.firstWeekday
        return (weekday - firstWeekday + 7) % 7
    }
}

// MARK: - Formatting
private extension MonthlyScoreCalendarCardLarge {
    func yearMonthString(for date: Date) -> String {
        let f = DateFormatter()
        f.calendar = cal
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("yMMMM")
        return f.string(from: date)
    }
}

// MARK: - Day Style Helpers
private extension MonthlyScoreCalendarCardLarge {
    func dayLabel(date: Date, record: DayRecord?) -> some View {
        let day = cal.component(.day, from: date)
        let isToday = cal.isDateInToday(date)

        return ZStack {
            if let r = record {
                // 有紀錄：用計算後的顏色圓圈
                Circle()
                    .fill(r.difficulty.color)
                    .frame(width: 22, height: 22)
            }

            Text("\(day)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(
                    record != nil ? .white : (isToday ? theme.accentColor : .primary)
                )
        }
        .frame(width: 22, height: 22)
    }

}

// ✅ 避免跟專案既有 DayCell 撞名
private struct MSDayCell: Identifiable {
    let id = UUID()
    let date: Date?
}
