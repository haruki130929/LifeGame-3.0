import SwiftUI

struct MoodEditView: View {
    @EnvironmentObject private var history: MoodHistoryStore
    @EnvironmentObject private var moodSettings: MoodSettingsStore
    @Environment(\.dismiss) private var dismiss

    /// 選擇要編輯的日期
    @State private var editDate: Date = Date()
    /// 每行的暫存分數
    @State private var scoreDrafts: [Date: Double] = [:]
    @State private var focusDrafts: [Date: Double] = [:]
    @State private var fatigueDrafts: [Date: Double] = [:]

    var body: some View {
        NavigationStack {
            List {
                // 日期選擇（有資料的日期亮色標記）
                Section {
                    MoodDatePicker(
                        selectedDate: $editDate,
                        hasData: datesWithData
                    )
                    .onChange(of: editDate) { _, _ in
                        scoreDrafts = [:]
                        focusDrafts = [:]
                        fatigueDrafts = [:]
                        loadDrafts()
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                ForEach(entries, id: \.hour) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(hourLabel(entry.hour))
                            .font(.subheadline.monospacedDigit().bold())

                        let defaultScore = Double(moodSettings.minScore + moodSettings.maxScore) / 2

                        // 情緒
                        sliderRow(
                            label: "情緒",
                            value: binding(for: entry, drafts: $scoreDrafts, keyPath: \.score, default: defaultScore),
                            range: moodSettings.scoreRange
                        )

                        // 專注力
                        sliderRow(
                            label: "專注力",
                            value: binding(for: entry, drafts: $focusDrafts, keyPath: \.focus, default: defaultScore),
                            range: moodSettings.scoreRange
                        )

                        // 疲勞度
                        sliderRow(
                            label: "疲勞度",
                            value: binding(for: entry, drafts: $fatigueDrafts, keyPath: \.fatigue, default: defaultScore),
                            range: moodSettings.scoreRange
                        )
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(entry.point != nil ? Color.accentColor.opacity(0.08) : Color.clear)
                    .swipeActions(edge: .trailing) {
                        if let point = entry.point {
                            Button(role: .destructive) {
                                history.delete(id: point.id)
                            } label: {
                                Label("刪除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("編輯心情紀錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { save(); dismiss() }
                }
            }
            .onAppear { loadDrafts() }
        }
    }

    // MARK: - Slider Row

    private func sliderRow(label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            Slider(value: value, in: range, step: 1)
            Text("\(Int(value.wrappedValue))")
                .font(.caption.bold().monospacedDigit())
                .frame(width: 24, alignment: .trailing)
        }
    }

    // MARK: - Binding Helper

    private func binding(for entry: (hour: Date, point: MoodPoint?), drafts: Binding<[Date: Double]>, keyPath: KeyPath<MoodPoint, Double?>, default defaultValue: Double) -> Binding<Double> {
        Binding<Double>(
            get: { drafts.wrappedValue[entry.hour] ?? entry.point?[keyPath: keyPath] ?? defaultValue },
            set: { drafts.wrappedValue[entry.hour] = $0 }
        )
    }

    private func binding(for entry: (hour: Date, point: MoodPoint?), drafts: Binding<[Date: Double]>, keyPath: KeyPath<MoodPoint, Double>, default defaultValue: Double) -> Binding<Double> {
        Binding<Double>(
            get: { drafts.wrappedValue[entry.hour] ?? entry.point?[keyPath: keyPath] ?? defaultValue },
            set: { drafts.wrappedValue[entry.hour] = $0 }
        )
    }

    // MARK: - Data

    /// 有心情資料的日期集合
    private var datesWithData: Set<DateComponents> {
        let cal = Calendar.current
        return Set(history.points.map { cal.dateComponents([.year, .month, .day], from: $0.timestamp) })
    }

    private var entries: [(hour: Date, point: MoodPoint?)] {
        let range = displayRange()
        return history.hourlyEntries(in: range.start...range.end)
    }

    private func displayRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startHour = moodSettings.chartStartHour
        let startOfDay = calendar.startOfDay(for: editDate)
        let dayStart = calendar.date(byAdding: .hour, value: startHour, to: startOfDay)!
        let dayEnd = calendar.date(byAdding: .hour, value: 24, to: dayStart)!

        // 如果是今天，只顯示到當前小時
        if calendar.isDateInToday(editDate) {
            let currentHour = calendar.dateInterval(of: .hour, for: Date())?.start ?? Date()
            return (dayStart, max(dayStart, currentHour))
        }

        // 過去的日期顯示完整 24 小時
        return (dayStart, dayEnd)
    }

    private func loadDrafts() {
        for entry in entries {
            if let point = entry.point {
                scoreDrafts[entry.hour] = point.score
                focusDrafts[entry.hour] = point.focus ?? 5
                fatigueDrafts[entry.hour] = point.fatigue ?? 5
            }
        }
    }

    private func save() {
        let allHours = Set(scoreDrafts.keys).union(focusDrafts.keys).union(fatigueDrafts.keys)
        for hour in allHours {
            let score = scoreDrafts[hour] ?? 5
            let focus = focusDrafts[hour]
            let fatigue = fatigueDrafts[hour]
            history.addOrUpdate(score: score, focus: focus, fatigue: fatigue, forHour: hour)
        }
    }

    // MARK: - Formatting

    private func hourLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00"
        let next = date.addingTimeInterval(3600)
        return "\(formatter.string(from: date))–\(formatter.string(from: next))"
    }
}

// MARK: - 自訂日曆選擇器（有資料的日期亮色標記）

private struct MoodDatePicker: View {
    @Binding var selectedDate: Date
    let hasData: Set<DateComponents>
    @EnvironmentObject private var theme: ThemeStore

    @State private var monthOffset: Int = 0
    private let cal = Calendar.current
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    private var displayMonth: Date {
        cal.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }

    var body: some View {
        VStack(spacing: 8) {
            // 月份導航
            HStack {
                Button { monthOffset -= 1 } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.semibold))
                }
                Spacer()
                Text(monthLabel)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button { monthOffset += 1 } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .disabled(monthOffset >= 0)
            }
            .padding(.horizontal, 16)

            // 星期標題
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)

            // 日期格子
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date {
                        dayCell(date)
                    } else {
                        Text("")
                            .frame(height: 32)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 10)
    }

    private var monthLabel: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "zh_TW")
        fmt.dateFormat = "yyyy年M月"
        return fmt.string(from: displayMonth)
    }

    private func dayCell(_ date: Date) -> some View {
        let day = cal.component(.day, from: date)
        let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
        let isToday = cal.isDateInToday(date)
        let isFuture = date > Date()
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let hasDataForDay = hasData.contains(comps)

        return Button {
            if !isFuture {
                selectedDate = date
            }
        } label: {
            Text("\(day)")
                .font(.caption.weight(isToday ? .bold : .regular))
                .frame(width: 32, height: 32)
                .foregroundStyle(
                    isFuture ? Color.secondary.opacity(0.3) :
                    isSelected ? Color.white :
                    hasDataForDay ? Color.primary :
                    Color.secondary.opacity(0.4)
                )
                .background(
                    isSelected ? theme.accentColor :
                    hasDataForDay ? theme.accentColor.opacity(0.15) :
                    Color.clear
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
    }

    private func daysInMonth() -> [Date?] {
        let comps = cal.dateComponents([.year, .month], from: displayMonth)
        guard let firstDay = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: firstDay) else {
            return []
        }

        let weekday = cal.component(.weekday, from: firstDay) - 1 // 0 = Sunday
        var days: [Date?] = Array(repeating: nil, count: weekday)

        for day in range {
            if let date = cal.date(bySetting: .day, value: day, of: firstDay) {
                days.append(date)
            }
        }

        return days
    }
}
