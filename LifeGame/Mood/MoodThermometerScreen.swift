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

                // 圖表（橫軸固定 8:00 起算）
                let displayRange = todayRangeStartingAt8()
                let chartPoints = buildChartPoints(
                    period: selectedPeriod,
                    displayRange: displayRange
                )

                MoodThermometerChartView(
                    points: chartPoints,
                    rangeStart: displayRange.start,
                    rangeEnd: displayRange.end,
                    period: selectedPeriod,
                    wakeUpTime: todayWakeUpTime
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

    @State private var showWakeTimePicker = false
    @State private var selectedWakeTime: Double = 8.0

    private var wakeUpBar: some View {
        HStack {
            Image(systemName: "sun.max.fill")
                .foregroundStyle(.orange)

            if let wake = moodSettings.wakeUpTime, Calendar.current.isDateInToday(wake) {
                Text("今日起床：\(wake.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    if let w = moodSettings.wakeUpTime {
                        let cal = Calendar.current
                        selectedWakeTime = Double(cal.component(.hour, from: w)) + (cal.component(.minute, from: w) >= 30 ? 0.5 : 0)
                    }
                    showWakeTimePicker = true
                } label: {
                    Text("修改")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } else {
                Button {
                    selectedWakeTime = 8.0
                    showWakeTimePicker = true
                } label: {
                    Text("設定起床時間")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.orange)
                }
            }

            Spacer()
        }
        .sheet(isPresented: $showWakeTimePicker) {
            wakeTimePicker
                .presentationDetents([.height(280)])
        }
    }

    private var wakeTimePicker: some View {
        let values: [Double] = {
            var result: [Double] = []
            for h in 0...23 {
                result.append(Double(h))
                result.append(Double(h) + 0.5)
            }
            return result
        }()

        return VStack(spacing: 16) {
            Text("選擇起床時間")
                .font(.headline)
                .padding(.top, 20)

            Picker("", selection: $selectedWakeTime) {
                ForEach(values, id: \.self) { v in
                    let hour = Int(v)
                    let min = v.truncatingRemainder(dividingBy: 1) >= 0.5 ? "30" : "00"
                    Text("\(hour):\(min)").tag(v)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)

            Button {
                let cal = Calendar.current
                let today = cal.startOfDay(for: Date())
                let hour = Int(selectedWakeTime)
                let minute = selectedWakeTime.truncatingRemainder(dividingBy: 1) >= 0.5 ? 30 : 0
                moodSettings.wakeUpTime = cal.date(bySettingHour: hour, minute: minute, second: 0, of: today)
                showWakeTimePicker = false
            } label: {
                Text("確定")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
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

    /// 圖表顯示範圍：固定 8:00 起算
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

    /// 今日起床時間（用於圖表上的標記線）
    private var todayWakeUpTime: Date? {
        guard let wake = moodSettings.wakeUpTime,
              Calendar.current.isDateInToday(wake) else { return nil }
        return wake
    }

    /// 過去 N 天的資料來源範圍
    private func sourceRange(days: Int, now: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        let start = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: now))!
        return (start, end)
    }
}
