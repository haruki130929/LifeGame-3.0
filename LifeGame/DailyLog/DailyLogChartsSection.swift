import SwiftUI
import Charts

// MARK: - 圖表時間區間

enum ChartRange: String, CaseIterable, Identifiable {
    case week = "1 週"
    case twoWeeks = "2 週"
    case month = "1 月"
    case threeMonths = "3 月"
    case all = "全部"

    var id: String { rawValue }

    var days: Int? {
        switch self {
        case .week:        return 7
        case .twoWeeks:    return 14
        case .month:       return 30
        case .threeMonths: return 90
        case .all:         return nil
        }
    }
}

/// 每日紀錄圖表區 — 橫向滑動，每個類別一張卡片
struct DailyLogChartsSection: View {
    let entries: [DailyLogEntry]
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var moduleStore: QuestionModuleStore
    @State private var selectedRange: ChartRange = .twoWeeks

    private var filteredEntries: [DailyLogEntry] {
        let sorted = entries.sorted { $0.date < $1.date }
        guard let days = selectedRange.days else { return sorted }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sorted.filter { $0.date >= cutoff }
    }

    var body: some View {
        VStack(spacing: 6) {
            // 區間選擇器
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ChartRange.allCases) { range in
                        Button {
                            withAnimation { selectedRange = range }
                        } label: {
                            Text(range.rawValue)
                                .font(.caption.weight(selectedRange == range ? .semibold : .regular))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedRange == range ? theme.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                                .foregroundStyle(selectedRange == range ? theme.accentColor : .secondary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            // 圖表卡片
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
        }
        .frame(height: 270)
    }

    // MARK: - 1. 情緒趨勢（心情、焦慮、疲勞）

    private var moodChart: some View {
        chartCard(title: "情緒趨勢") {
            Chart {
                ForEach(filteredEntries) { entry in
                    lineMark(date: entry.date, value: moodScore(entry), series: "心情", color: .orange)
                    lineMark(date: entry.date, value: anxietyScore(entry), series: "焦慮", color: .red)
                    lineMark(date: entry.date, value: fatigueScore(entry), series: "疲勞", color: .purple)
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
                AxisMarks(values: .stride(by: .day, count: 2)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(zhDateLabel(date))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
        }
    }

    // MARK: - 2. 睡眠趨勢

    private var sleepChart: some View {
        let sleepData = filteredEntries.compactMap { entry -> (id: UUID, date: Date, hours: Double)? in
            // 優先從 customAnswers 取睡眠時長
            if let module = moduleStore.modules.first(where: { $0.kind == .sleep }),
               let questions = module.questions,
               let q = questions.first(where: { $0.title.contains("睡眠時長") }),
               let answer = entry.customAnswers.first(where: { $0.questionId == q.id }),
               let v = answer.intValue {
                return (entry.id, entry.date, Double(v))
            }
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
                AxisMarks(values: .stride(by: .day, count: 2)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(zhDateLabel(date))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
        }
    }

    // MARK: - 3. 身體不適

    private var bodyChart: some View {
        // 取有疼痛紀錄的資料
        let painData = filteredEntries.flatMap { entry in
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
                    AxisMarks(values: .stride(by: .day, count: 2)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(zhDateLabel(date))
                                    .font(.caption2)
                            }
                        }
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
                ForEach(filteredEntries) { entry in
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
                AxisMarks(values: .stride(by: .day, count: 2)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(zhDateLabel(date))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
        }
    }

    // MARK: - 5. 起床/就寢時間

    private var timeChart: some View {
        let timeData = filteredEntries.compactMap { entry -> (id: UUID, date: Date, wake: Double, bed: Double)? in
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
                    AxisMarks(values: .stride(by: .day, count: 2)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(zhDateLabel(date))
                                    .font(.caption2)
                            }
                        }
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

    /// 從 customAnswers 或原生欄位取 slider/number 值
    private func customInt(entry: DailyLogEntry, moduleKind: ModuleKind, questionTitle: String, fallback: Int) -> Int {
        if let module = moduleStore.modules.first(where: { $0.kind == moduleKind }),
           let questions = module.questions,
           let q = questions.first(where: { $0.title == questionTitle }),
           let answer = entry.customAnswers.first(where: { $0.questionId == q.id }),
           let v = answer.intValue {
            return v
        }
        return fallback
    }

    /// 情緒分數（優先 customAnswers）
    private func moodScore(_ entry: DailyLogEntry) -> Int {
        customInt(entry: entry, moduleKind: .moodMental, questionTitle: "整體情緒分數", fallback: entry.overallMoodScore)
    }

    private func anxietyScore(_ entry: DailyLogEntry) -> Int {
        customInt(entry: entry, moduleKind: .moodMental, questionTitle: "焦慮程度", fallback: entry.anxietyScore)
    }

    private func fatigueScore(_ entry: DailyLogEntry) -> Int {
        customInt(entry: entry, moduleKind: .body, questionTitle: "今日疲勞程度", fallback: entry.fatigueScore)
    }

    private func lineMark(date: Date, value: Int, series: String, color: Color) -> some ChartContent {
        LineMark(
            x: .value("日期", date, unit: .day),
            y: .value("分數", value),
            series: .value("類別", series)
        )
        .foregroundStyle(color)
        .interpolationMethod(.catmullRom)
    }

    private func zhDateLabel(_ date: Date) -> String {
        let cal = Calendar.current
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        return "\(m)/\(d)"
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
