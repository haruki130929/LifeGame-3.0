import SwiftUI
import Charts

struct MoodThermometerChartView: View {
    let points: [MoodPoint]
    let rangeStart: Date          // 永遠是今天 8:00
    let rangeEnd: Date            // 永遠是隔天 8:00
    var period: MoodTimePeriod = .day

    @EnvironmentObject private var theme: ThemeStore

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16)

        VStack(alignment: .leading, spacing: 8) {
            Text(period.chartTitle)
                .font(.headline)

            Chart {
                ForEach(points) { p in
                    LineMark(
                        x: .value("時間", p.timestamp),
                        y: .value("分數", p.score)
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("時間", p.timestamp),
                        y: .value("分數", p.score)
                    )
                }
            }
            .chartYScale(domain: 0...10)
            .chartXScale(domain: rangeStart...rangeEnd)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 2, 4, 6, 8, 10])
            }
            .chartXAxis {
                // 橫軸永遠是一天中的時間，每 4 小時一刻度
                AxisMarks(values: .stride(by: .hour, count: 4)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.hour(.twoDigits(amPM: .abbreviated)))
                }
            }
            .frame(height: 220 * Layout.heightScale)
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
