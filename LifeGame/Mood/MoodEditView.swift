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
    @State private var sleepHours: Set<Date> = []

    var body: some View {
        NavigationStack {
            List {
                // 日期選擇
                Section {
                    DatePicker("選擇日期", selection: $editDate, in: ...Date(), displayedComponents: .date)
                        .onChange(of: editDate) { _, _ in
                            scoreDrafts = [:]
                            focusDrafts = [:]
                            fatigueDrafts = [:]
                            loadDrafts()
                        }
                }

                ForEach(entries, id: \.hour) { entry in
                    let isAsleep = sleepHours.contains(entry.hour)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(hourLabel(entry.hour))
                                .font(.subheadline.monospacedDigit().bold())
                            Spacer()
                            Button {
                                toggleSleep(entry.hour)
                            } label: {
                                Text(isAsleep ? "尚未起床" : "標記未起床")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(isAsleep ? Color.secondary.opacity(0.2) : Color.clear)
                                    .clipShape(Capsule())
                                    .foregroundStyle(isAsleep ? .secondary : .tertiary)
                            }
                        }

                        if isAsleep {
                            Text("💤 睡眠中")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            let defaultScore = Double(moodSettings.minScore + moodSettings.maxScore) / 2

                            sliderRow(
                                label: String(localized: "情緒"),
                                value: binding(for: entry, drafts: $scoreDrafts, keyPath: \.score, default: defaultScore),
                                range: moodSettings.scoreRange
                            )
                            sliderRow(
                                label: String(localized: "專注力"),
                                value: binding(for: entry, drafts: $focusDrafts, keyPath: \.focus, default: defaultScore),
                                range: moodSettings.scoreRange
                            )
                            sliderRow(
                                label: String(localized: "疲勞度"),
                                value: binding(for: entry, drafts: $fatigueDrafts, keyPath: \.fatigue, default: defaultScore),
                                range: moodSettings.scoreRange
                            )
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(isAsleep ? Color.secondary.opacity(0.04) : entry.point != nil ? Color.accentColor.opacity(0.08) : Color.clear)
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

    private var entries: [(hour: Date, point: MoodPoint?)] {
        let range = displayRange()
        return history.hourlyEntries(in: range.start...range.end)
    }

    private func displayRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: editDate)
        let dayStart = calendar.date(byAdding: .hour, value: 8, to: startOfDay)!
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
        sleepHours = []
        let currentEntries = entries
        let firstDataIndex = currentEntries.firstIndex(where: { $0.point != nil })

        for (index, entry) in currentEntries.enumerated() {
            if let point = entry.point {
                scoreDrafts[entry.hour] = point.score
                focusDrafts[entry.hour] = point.focus ?? 5
                fatigueDrafts[entry.hour] = point.fatigue ?? 5
            } else if let first = firstDataIndex, index < first {
                // 第一筆資料之前的空白小時，標記為睡眠
                sleepHours.insert(entry.hour)
            }
        }
    }

    private func toggleSleep(_ hour: Date) {
        if sleepHours.contains(hour) {
            sleepHours.remove(hour)
        } else {
            sleepHours.insert(hour)
            // 清掉該小時的 drafts
            scoreDrafts.removeValue(forKey: hour)
            focusDrafts.removeValue(forKey: hour)
            fatigueDrafts.removeValue(forKey: hour)
        }
    }

    private func save() {
        let allHours = Set(scoreDrafts.keys).union(focusDrafts.keys).union(fatigueDrafts.keys)
        for hour in allHours {
            // 跳過標記為睡眠的小時
            guard !sleepHours.contains(hour) else { continue }
            let score = scoreDrafts[hour] ?? 5
            let focus = focusDrafts[hour]
            let fatigue = fatigueDrafts[hour]
            history.addOrUpdate(score: score, focus: focus, fatigue: fatigue, forHour: hour)
        }

        // 刪除標記為睡眠的已有紀錄
        for hour in sleepHours {
            if let entry = entries.first(where: { $0.hour == hour }), let point = entry.point {
                history.delete(id: point.id)
            }
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
