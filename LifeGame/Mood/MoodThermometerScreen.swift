import SwiftUI

struct MoodThermometerScreen: View {
    @EnvironmentObject private var mood: MoodStore
    @EnvironmentObject private var history: MoodHistoryStore
    @EnvironmentObject private var fab: FabStore

    @EnvironmentObject private var moodSettings: MoodSettingsStore
    @State private var selectedPeriod: MoodTimePeriod = .day
    @State private var showHourlyLimitAlert = false
    @State private var showRecordedToast = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // 日 / 週 / 月 Tab
                FolderTabs(
                    tabs: MoodTimePeriod.allCases,
                    selection: $selectedPeriod,
                    title: { $0.title }
                )

                // 起床時間標記
                wakeUpBar

                // 圖表（橫軸從起床時間開始）
                let displayRange = todayRangeFromWakeUp()
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

            }
            .padding()
        }
        .overlay {
            if showRecordedToast {
                VStack {
                    Text("已紀錄 ✓")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.green.gradient, in: Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    Spacer()
                }
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: showRecordedToast)
        .navigationTitle("心情溫度計")
        .animation(.easeInOut(duration: 0.2), value: selectedPeriod)
        .onAppear {
            fab.apply(context: .feature(.moodThermometer))
        }
        .onDisappear {
            fab.popActions()
        }
        .featureTutorial(.moodThermometer)
    }

    // MARK: - 起床時間標記

    private var wakeUpBar: some View {
        HStack {
            if let wake = moodSettings.wakeUpTime, Calendar.current.isDateInToday(wake) {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.orange)
                Text("今日起床：\(wake.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    moodSettings.markWakeUp()
                } label: {
                    Label("標記起床時間", systemImage: "sun.max")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }
            Spacer()
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

            // chartStartHour~23 點 → 今天；0~(chartStartHour-1) 點 → 隔天
            let startH = moodSettings.chartStartHour
            let baseDate: Date
            if hour >= startH {
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

    /// 圖表顯示範圍：從起床時間（或預設 8:00）到 24 小時後
    private func todayRangeFromWakeUp(now: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let hour = moodSettings.chartStartHour
        let startOfDay = calendar.startOfDay(for: now)
        let todayStart = calendar.date(byAdding: .hour, value: hour, to: startOfDay)!

        let start: Date = (now < todayStart)
            ? calendar.date(byAdding: .day, value: -1, to: todayStart)!
            : todayStart
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
