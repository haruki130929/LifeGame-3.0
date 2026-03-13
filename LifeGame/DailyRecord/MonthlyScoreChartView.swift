import SwiftUI
import Charts

struct MonthlyScoreChartView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @EnvironmentObject private var theme: ThemeStore

    enum Period: String, CaseIterable {
        case week = "週"
        case month = "月"
    }

    @State private var period: Period = .week

    private let cal = Calendar.current

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16)

        VStack(alignment: .leading, spacing: 10) {
            headerRow
            chartContent
        }
        .padding()
        .background {
            if theme.isDark {
                shape.fill(.thinMaterial)
            } else {
                shape.fill(Color.white)
            }
        }
        .overlay(
            shape.strokeBorder(
                theme.isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.10),
                lineWidth: 1
            )
        )
        .shadow(
            color: theme.isDark ? .clear : .black.opacity(0.08),
            radius: 8, x: 0, y: 3
        )
        .clipShape(shape)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("分數趨勢")
                .font(.headline)
            Spacer()
            Picker("", selection: $period) {
                ForEach(Period.allCases, id: \.self) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
        }
    }

    // MARK: - Chart

    @ViewBuilder
    private var chartContent: some View {
        let data = chartData
        if data.isEmpty {
            Text("尚無資料")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 180)
        } else {
            chartView(data: data)
        }
    }

    private func chartView(data: [ChartPoint]) -> some View {
        Chart {
            ForEach(data) { point in
                LineMark(
                    x: .value("日期", point.date),
                    y: .value("分數", point.median)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.accentColor)

                PointMark(
                    x: .value("日期", point.date),
                    y: .value("分數", point.median)
                )
                .foregroundStyle(difficultyColor(point.median))
                .symbolSize(30)
            }

            RuleMark(y: .value("", 70))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundStyle(Color.green.opacity(0.5))
            RuleMark(y: .value("", 30))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundStyle(Color.red.opacity(0.5))
        }
        .chartYScale(domain: 0...100)
        .chartXScale(domain: xDomain)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 30, 50, 70, 100])
        }
        .chartXAxis {
            AxisMarks(values: xAxisValues) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: xAxisFormat)
            }
        }
        .frame(height: 200)
    }
}

// MARK: - Data
private extension MonthlyScoreChartView {

    struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let median: Int
    }

    var chartData: [ChartPoint] {
        let allRecords = historyStore.records.values
        let range = dateRange

        return allRecords
            .compactMap { record -> ChartPoint? in
                guard let date = parseDateKey(record.dateKey),
                      date >= range.start, date < range.end else { return nil }
                return ChartPoint(date: date, median: record.median)
            }
            .sorted { $0.date < $1.date }
    }

    var dateRange: (start: Date, end: Date) {
        let today = cal.startOfDay(for: Date())
        switch period {
        case .week:
            let start = cal.date(byAdding: .day, value: -6, to: today)!
            let end = cal.date(byAdding: .day, value: 1, to: today)!
            return (start, end)
        case .month:
            let start = cal.date(byAdding: .day, value: -29, to: today)!
            let end = cal.date(byAdding: .day, value: 1, to: today)!
            return (start, end)
        }
    }

    var xDomain: ClosedRange<Date> {
        let range = dateRange
        return range.start...range.end
    }

    var xAxisValues: AxisMarkValues {
        switch period {
        case .week:
            return .stride(by: .day, count: 1)
        case .month:
            return .stride(by: .day, count: 5)
        }
    }

    var xAxisFormat: Date.FormatStyle {
        .dateTime.month(.defaultDigits).day()
    }

    func difficultyColor(_ median: Int) -> Color {
        if median >= 70 { return .green }
        else if median >= 30 { return .orange }
        else { return .red }
    }
}
