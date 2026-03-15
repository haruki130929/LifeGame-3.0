import SwiftUI

struct MoodThermometerScreen: View {
    @EnvironmentObject private var mood: MoodStore
    @EnvironmentObject private var history: MoodHistoryStore
    @EnvironmentObject private var fab: FabStore

    @State private var selectedPeriod: MoodTimePeriod = .day
    @State private var showHourlyLimitAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // 日 / 週 / 月 Tab
                FolderTabs(
                    tabs: MoodTimePeriod.allCases,
                    selection: $selectedPeriod,
                    title: { $0.title }
                )

                // 圖表（橫軸永遠是 8:00~隔天 8:00 的時間軸）
                let displayRange = todayRangeStartingAt8()
                let chartPoints = buildChartPoints(
                    period: selectedPeriod,
                    displayRange: displayRange
                )

                MoodThermometerChartView(
                    points: chartPoints,
                    rangeStart: displayRange.start,
                    rangeEnd: displayRange.end,
                    period: selectedPeriod
                )

                MoodThermometerCard(mood: mood)

                Button {
                    let previousHour = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
                    let ok = history.add(score: mood.score, at: previousHour)
                    if !ok { showHourlyLimitAlert = true }
                } label: {
                    Label("記錄上一小時心情", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .alert("上一個小時已經記錄過了", isPresented: $showHourlyLimitAlert) {
                    Button("好", role: .cancel) { }
                } message: {
                    Text("每小時只能記錄一次，等這個小時結束後再記錄。")
                }

            }
            .padding()
        }
        .navigationTitle("心情溫度計")
        .animation(.easeInOut(duration: 0.2), value: selectedPeriod)
        .onAppear {
            fab.apply(context: .feature(.moodThermometer))
        }
        .onDisappear {
            fab.popActions()
        }
    }

    // MARK: - 建立圖表資料點

    /// 根據選擇的時段，產生要顯示在圖表上的資料點
    /// - 日：直接回傳今天的原始資料
    /// - 週/月：把多天的資料按小時分組取平均，映射回今天的 8:00~隔天 8:00 時間軸
    private func buildChartPoints(
        period: MoodTimePeriod,
        displayRange: (start: Date, end: Date)
    ) -> [MoodPoint] {
        switch period {
        case .day:
            return history.points(in: displayRange.start...displayRange.end)

        case .week:
            let source = sourceRange(days: 7)
            let raw = history.points(in: source.start...source.end)
            return averagedByHour(points: raw, displayStart: displayRange.start)

        case .month:
            let source = sourceRange(days: 30)
            let raw = history.points(in: source.start...source.end)
            return averagedByHour(points: raw, displayStart: displayRange.start)
        }
    }

    /// 將多天的 MoodPoint 按「小時」分組取平均，映射到今天的時間軸上
    private func averagedByHour(points: [MoodPoint], displayStart: Date) -> [MoodPoint] {
        let calendar = Calendar.current

        // 按小時分組
        var buckets: [Int: [Double]] = [:]
        for p in points {
            let hour = calendar.component(.hour, from: p.timestamp)
            buckets[hour, default: []].append(p.score)
        }

        // 把每個小時的平均值映射到 displayStart 所在的那一天
        let dayStart = calendar.startOfDay(for: displayStart) // 今天 00:00

        var result: [MoodPoint] = []
        for (hour, scores) in buckets {
            let avg = scores.reduce(0, +) / Double(scores.count)

            // 8~23 點 → 今天；0~7 點 → 隔天（因為時間軸是 8:00 起算）
            let baseDate: Date
            if hour >= 8 {
                baseDate = dayStart
            } else {
                baseDate = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            }
            let timestamp = calendar.date(byAdding: .hour, value: hour, to: baseDate)!
            result.append(MoodPoint(timestamp: timestamp, score: avg))
        }

        return result.sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - 日期範圍

    /// 「今天 8:00」到「隔天 8:00」— 圖表顯示範圍（永遠固定）
    private func todayRangeStartingAt8(now: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let today8 = calendar.date(byAdding: .hour, value: 8, to: startOfDay)!

        let start: Date = (now < today8)
            ? calendar.date(byAdding: .day, value: -1, to: today8)!
            : today8
        let end = calendar.date(byAdding: .hour, value: 24, to: start)!
        return (start, end)
    }

    /// 過去 N 天的資料來源範圍
    private func sourceRange(days: Int, now: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        let start = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: now))!
        return (start, end)
    }
}
