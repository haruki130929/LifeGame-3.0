import SwiftUI
import Charts

/// 每日紀錄圖表區 — 橫向滑動，每個類別一張卡片
struct DailyLogChartsSection: View {
    let entries: [DailyLogEntry]
    @EnvironmentObject private var theme: ThemeStore

    /// 最近 14 天的資料（按日期排序）
    private var recentEntries: [DailyLogEntry] {
        let sorted = entries.sorted { $0.date < $1.date }
        return Array(sorted.suffix(14))
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                moodChart
                sleepChart
                bodyChart
                focusChart
                timeChart
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(height: 230)
    }

    // MARK: - 1. 情緒趨勢（心情、焦慮、疲勞）

    private var moodChart: some View {
        chartCard(title: "情緒趨勢") {
            Chart {
                ForEach(recentEntries) { entry in
                    lineMark(date: entry.date, value: entry.overallMoodScore, series: "心情", color: .orange)
                    lineMark(date: entry.date, value: entry.anxietyScore, series: "焦慮", color: .red)
                    lineMark(date: entry.date, value: entry.fatigueScore, series: "疲勞", color: .purple)
                }
            }
            .chartYScale(domain: 0...10)
            .chartForegroundStyleScale([
                "心情": Color.orange,
                "焦慮": Color.red,
                "疲勞": Color.purple
            ])
            .chartLegend(position: .bottom, spacing: 8)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
        }
    }

    // MARK: - 2. 睡眠趨勢

    private var sleepChart: some View {
        let sleepData = recentEntries.compactMap { entry -> (id: UUID, date: Date, hours: Double)? in
            guard let h = entry.sleepHours.doubleValue else { return nil }
            return (entry.id, entry.date, h)
        }

        return chartCard(title: "睡眠時數") {
            Chart {
                ForEach(sleepData, id: \.id) { item in
                    BarMark(
                        x: .value("日期", item.date, unit: .day),
                        y: .value("小時", item.hours)
                    )
                    .foregroundStyle(theme.accentColor.opacity(0.7))
                    .cornerRadius(4)
                }
            }
            .chartYScale(domain: 0...12)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
        }
    }

    // MARK: - 3. 身體不適

    private var bodyChart: some View {
        // 取有疼痛紀錄的資料
        let painData = recentEntries.flatMap { entry in
            entry.painScoreByArea.map { (area, score) in
                (id: UUID(), date: entry.date, area: area.rawValue, score: score)
            }
        }

        return chartCard(title: "身體不適") {
            if painData.isEmpty {
                ContentUnavailableView("沒有不適紀錄", systemImage: "heart.fill", description: nil)
                    .frame(height: 150)
            } else {
                Chart {
                    ForEach(painData, id: \.id) { item in
                        PointMark(
                            x: .value("日期", item.date, unit: .day),
                            y: .value("程度", item.score)
                        )
                        .foregroundStyle(by: .value("部位", item.area))

                        LineMark(
                            x: .value("日期", item.date, unit: .day),
                            y: .value("程度", item.score)
                        )
                        .foregroundStyle(by: .value("部位", item.area))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 0...10)
                .chartLegend(position: .bottom, spacing: 8)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis { AxisMarks(position: .leading) }
            }
        }
    }

    // MARK: - 4. 專注與完成度

    private var focusChart: some View {
        chartCard(title: "待辦完成度") {
            Chart {
                ForEach(recentEntries) { entry in
                    if entry.todoPartialTotal > 0 {
                        BarMark(
                            x: .value("日期", entry.date, unit: .day),
                            y: .value("完成", entry.todoPartialDone)
                        )
                        .foregroundStyle(Color.green.opacity(0.7))
                        .cornerRadius(4)

                        BarMark(
                            x: .value("日期", entry.date, unit: .day),
                            y: .value("未完成", entry.todoPartialTotal - entry.todoPartialDone)
                        )
                        .foregroundStyle(Color.gray.opacity(0.3))
                        .cornerRadius(4)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
        }
    }

    // MARK: - 5. 起床/就寢時間

    private var timeChart: some View {
        let timeData = recentEntries.compactMap { entry -> (id: UUID, date: Date, wake: Double, bed: Double)? in
            guard let w = entry.wakeTime.dateValue, let b = entry.bedTime.dateValue else { return nil }
            let cal = Calendar.current
            let wakeHour = Double(cal.component(.hour, from: w)) + Double(cal.component(.minute, from: w)) / 60.0
            let bedHour = Double(cal.component(.hour, from: b)) + Double(cal.component(.minute, from: b)) / 60.0
            return (entry.id, entry.date, wakeHour, bedHour)
        }

        return chartCard(title: "起床 / 就寢時間") {
            if timeData.isEmpty {
                ContentUnavailableView("沒有時間紀錄", systemImage: "clock", description: nil)
                    .frame(height: 150)
            } else {
                Chart {
                    ForEach(timeData, id: \.id) { item in
                        LineMark(
                            x: .value("日期", item.date, unit: .day),
                            y: .value("時", item.wake),
                            series: .value("類別", "起床")
                        )
                        .foregroundStyle(.orange)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("日期", item.date, unit: .day),
                            y: .value("時", item.wake)
                        )
                        .foregroundStyle(.orange)

                        LineMark(
                            x: .value("日期", item.date, unit: .day),
                            y: .value("時", item.bed),
                            series: .value("類別", "就寢")
                        )
                        .foregroundStyle(.indigo)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("日期", item.date, unit: .day),
                            y: .value("時", item.bed)
                        )
                        .foregroundStyle(.indigo)
                    }
                }
                .chartYScale(domain: 0...24)
                .chartForegroundStyleScale([
                    "起床": Color.orange,
                    "就寢": Color.indigo
                ])
                .chartLegend(position: .bottom, spacing: 8)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let h = value.as(Double.self) {
                                Text("\(Int(h)):00")
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func lineMark(date: Date, value: Int, series: String, color: Color) -> some ChartContent {
        LineMark(
            x: .value("日期", date, unit: .day),
            y: .value("分數", value),
            series: .value("類別", series)
        )
        .foregroundStyle(color)
        .interpolationMethod(.catmullRom)
    }

    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            content()
                .frame(height: 150)
        }
        .padding(14)
        .frame(width: 300)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
