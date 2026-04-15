import SwiftUI

struct MoodEditView: View {
    @EnvironmentObject private var history: MoodHistoryStore
    @EnvironmentObject private var moodSettings: MoodSettingsStore
    @Environment(\.dismiss) private var dismiss

    /// 每行的暫存分數
    @State private var scoreDrafts: [Date: Double] = [:]
    @State private var focusDrafts: [Date: Double] = [:]
    @State private var fatigueDrafts: [Date: Double] = [:]

    var body: some View {
        NavigationStack {
            List {
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
            .navigationTitle("編輯今日紀錄")
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
        let now = Date()
        let startHour = moodSettings.chartStartHour
        let startOfDay = calendar.startOfDay(for: now)
        let todayStart = calendar.date(byAdding: .hour, value: startHour, to: startOfDay)!

        let start: Date = (now < todayStart)
            ? calendar.date(byAdding: .day, value: -1, to: todayStart)!
            : todayStart

        let currentHour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        return (start, max(start, currentHour))
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
