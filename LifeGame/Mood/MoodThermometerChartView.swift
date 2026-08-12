import SwiftUI
import Charts

struct MoodThermometerChartView: View {
    let points: [MoodPoint]
    let rangeStart: Date
    let rangeEnd: Date
    var period: MoodTimePeriod = .day
    var wakeUpTime: Date? = nil

    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var moodSettings: MoodSettingsStore

    private struct ChartEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let value: Double
        let category: String
    }

    private var chartEntries: [ChartEntry] {
        var result: [ChartEntry] = []
        for p in points {
            result.append(ChartEntry(timestamp: p.timestamp, value: p.score, category: String(localized: "情緒")))
            if let focus = p.focus {
                result.append(ChartEntry(timestamp: p.timestamp, value: focus, category: String(localized: "專注力")))
            }
            if let fatigue = p.fatigue {
                result.append(ChartEntry(timestamp: p.timestamp, value: fatigue, category: String(localized: "疲勞度")))
            }
        }
        return result
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16)

        VStack(alignment: .leading, spacing: 8) {
            Text(period.chartTitle)
                .font(.headline)

            Chart {
                ForEach(chartEntries) { entry in
                    LineMark(
                        x: .value("時間", entry.timestamp),
                        y: .value("分數", entry.value),
                        series: .value("類別", entry.category)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(by: .value("類別", entry.category))

                    PointMark(
                        x: .value("時間", entry.timestamp),
                        y: .value("分數", entry.value)
                    )
                    .foregroundStyle(by: .value("類別", entry.category))
                }

                // 起床時間標記線
                if let wake = wakeUpTime {
                    RuleMark(x: .value("起床", wake))
                        .foregroundStyle(.orange.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("起床")
                                .font(.caption2)
                                .foregroundStyle(.orange.opacity(0.6))
                        }
                }
            }
            .chartForegroundStyleScale([
                String(localized: "情緒"): Color.orange,
                String(localized: "專注力"): Color.blue,
                String(localized: "疲勞度"): Color.purple
            ])
            .chartYScale(domain: moodSettings.scoreRange)
            .chartXScale(domain: rangeStart...rangeEnd)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 4)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.hour(.twoDigits(amPM: .abbreviated)))
                }
            }
            .chartLegend(position: .bottom)
            .frame(height: 220 * AppLayout.heightScale)
            .padding(.vertical, 8)
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
                theme.isDark
                    ? Color.white.opacity(0.06)
                    : Color.black.opacity(0.10),
                lineWidth: 1
            )
        )
        .shadow(
            color: theme.isDark ? .black.opacity(0.3) : .black.opacity(0.08),
            radius: theme.isDark ? 10 : 8,
            x: 0,
            y: theme.isDark ? 6 : 3
        )
        .clipShape(shape)
    }
}
