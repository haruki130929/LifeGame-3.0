import SwiftUI
import Foundation

struct MonthlyScoreCalendarCardLarge: View {
    @EnvironmentObject private var monthlyScoreStore: MonthlyScoreStore
    
    // ✅ 跟你專案呼叫方式對齊：MonthlyScoreCalendarCardLarge(title:icon:)
    private let title: String
    private let icon: String
    
    init(title: String = "月分數", icon: String = "calendar") {
        self.title = title
        self.icon = icon
    }
    
    // MARK: - UI State
    @State private var showingEditor = false
    @State private var selectedDate = Date()
    @State private var editScore = 0
    @State private var hasScore = false
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
            .sheet(isPresented: $showingEditor) {
                editorSheet
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
            
            Button { monthOffset += 1 } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
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
                let score = monthlyScoreStore.score(for: date)
                
                VStack(spacing: 4) {
                    // ✅ 行事曆風格：有分數 → 實心圓包住日期
                    dayLabel(date: date, score: score)
                }
                .frame(maxWidth: .infinity, minHeight: 42)
                .contentShape(Rectangle())
                .onTapGesture { openEditor(for: date) }
                
            } else {
                Color.clear.frame(minHeight: 42)
            }
        }
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Editor Sheet
private extension MonthlyScoreCalendarCardLarge {
    var editorSheet: some View {
        NavigationStack {
            Form {
                Section("日期") {
                    Text(dateString(selectedDate))
                }
                
                Section("分數") {
                    Toggle("有分數", isOn: $hasScore)
                        .onChange(of: hasScore) { _, newValue in
                            if newValue {
                                monthlyScoreStore.setScore(editScore, for: selectedDate)
                            } else {
                                monthlyScoreStore.setScore(nil, for: selectedDate)
                            }
                        }
                    
                    Stepper(value: $editScore, in: 0...999) {
                        Text("分數：\(editScore)")
                    }
                    .disabled(!hasScore)
                    .onChange(of: editScore) { _, newValue in
                        guard hasScore else { return }
                        monthlyScoreStore.setScore(newValue, for: selectedDate)
                    }
                    
                    if hasScore {
                        Button(role: .destructive) {
                            hasScore = false
                            monthlyScoreStore.setScore(nil, for: selectedDate)
                        } label: {
                            Text("刪除這天分數")
                        }
                    }
                }
            }
            .navigationTitle("編輯分數")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { showingEditor = false }
                }
            }
        }
    }
    
    func openEditor(for date: Date) {
        selectedDate = date
        if let s = monthlyScoreStore.score(for: date) {
            editScore = s
            hasScore = true
        } else {
            editScore = 0
            hasScore = false
        }
        showingEditor = true
    }
}

// MARK: - Calendar Data
private extension MonthlyScoreCalendarCardLarge {
    var selectedMonthBase: Date {
        cal.date(byAdding: .month, value: monthOffset, to: startOfMonth(Date())) ?? Date()
    }
    
    var weekdaySymbols: [String] {
        let symbols = cal.shortStandaloneWeekdaySymbols
        let shift = cal.firstWeekday - 1
        return Array(symbols[shift...]) + Array(symbols[..<shift])
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
        f.locale = Locale(identifier: "zh_TW")
        f.dateFormat = "yyyy年 M月"
        return f.string(from: date)
    }
    
    func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = cal
        f.locale = Locale(identifier: "zh_TW")
        f.dateFormat = "yyyy/MM/dd"
        return f.string(from: date)
    }
}

// MARK: - Day Style Helpers (✅ 這些一定要在 struct 裡面，才看得到 cal)
private extension MonthlyScoreCalendarCardLarge {
    func dayLabel(date: Date, score: Int?) -> some View {
        let day = cal.component(.day, from: date)
        let hasScore = (score != nil)
        
        return ZStack {
            if hasScore {
                Circle()
                    .fill(scoreCircleColor(score ?? 0))
                    .frame(width: 26, height: 26)
            }
            
            Text("\(day)")
                .font(.caption.weight(.semibold))
                .foregroundColor(
                    hasScore
                    ? .white
                    : (cal.isDateInToday(date) ? .accentColor : .primary)
                )
        }
        .frame(height: 26)
    }
    
    func scoreCircleColor(_ score: Int) -> Color {
        // ✅ 先用分級色；想固定就 return .accentColor
        switch score {
        case ..<4: return .red
        case 4..<8: return .yellow
        default: return .green
        }
    }
}

// ✅ 避免跟專案既有 DayCell 撞名
private struct MSDayCell: Identifiable {
    let id = UUID()
    let date: Date?
}
