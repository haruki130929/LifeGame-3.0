// File: History/HistoryView.swift
import SwiftUI
import Charts

struct HistoryView: View {
    @ObservedObject var history: HistoryStore
    @State private var month: Date = Date()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                calendarGrid
                Divider().padding(.vertical, 8)
                chartSection
            }
            .padding()
        }
        .navigationTitle("回顧")
    }
    
    private var header: some View {
        HStack {
            Button { month = shiftMonth(month, by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Text(monthTitle(month))
                .font(.title3).fontWeight(.semibold)
            
            Spacer()
            
            Button { month = shiftMonth(month, by: 1) } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var calendarGrid: some View {
        let cal = calendarTW()
        let days = makeCalendarDays(for: month, calendar: cal)
        
        return VStack(alignment: .leading, spacing: 10) {
            let weekSymbols = cal.shortWeekdaySymbols
            HStack {
                ForEach(weekSymbols, id: \.self) { s in
                    Text(s)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 10) {
                ForEach(days, id: \.self) { d in
                    DayCell(date: d, month: month, record: history.record(for: d))
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var chartSection: some View {
        let records = history.records(in: month)
        
        return VStack(alignment: .leading, spacing: 10) {
            Text("本月走勢")
                .font(.headline)
            
            if records.isEmpty {
                Text("本月還沒有結算資料。")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            } else {
                Chart {
                    ForEach(records, id: \.dateKey) { r in
                        if let d = parseDateKey(r.dateKey) {
                            LineMark(x: .value("Date", d),
                                     y: .value("Score", r.score))
                            PointMark(x: .value("Date", d),
                                      y: .value("Score", r.score))
                        }
                    }
                }
                .frame(height: 180)
            }
            
            HStack(spacing: 10) {
                LegendDot(color: .green, text: "輕鬆 70")
                LegendDot(color: .orange, text: "中等 50")
                LegendDot(color: .red, text: "有點吃力 30")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct LegendDot: View {
    let color: Color
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(text)
        }
    }
}

struct DayCell: View {
    let date: Date
    let month: Date
    let record: DayRecord?
    
    var body: some View {
        let cal = calendarTW()
        let isInMonth = cal.isDate(date, equalTo: month, toGranularity: .month)
        let day = cal.component(.day, from: date)
        
        VStack(spacing: 6) {
            Text("\(day)")
                .font(.caption)
                .foregroundStyle(isInMonth ? .primary : .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let record {
                Circle()
                    .fill(record.difficulty.color)
                    .frame(width: 14, height: 14)
                    .overlay {
                        Text("\(record.score)")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 14, height: 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(height: 52)
        .background(.ultraThinMaterial.opacity(isInMonth ? 1 : 0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
