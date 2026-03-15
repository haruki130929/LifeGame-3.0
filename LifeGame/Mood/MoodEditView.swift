import SwiftUI

struct MoodEditView: View {
    @EnvironmentObject private var history: MoodHistoryStore
    @EnvironmentObject private var moodSettings: MoodSettingsStore
    @Environment(\.dismiss) private var dismiss

    /// 每行的暫存分數 (hourStart → score)
    @State private var drafts: [Date: Double] = [:]

    var body: some View {
        NavigationStack {
            List {
                ForEach(entries, id: \.hour) { entry in
                    HStack {
                        Text(hourLabel(entry.hour))
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 110, alignment: .leading)

                        let defaultScore = Double(moodSettings.minScore + moodSettings.maxScore) / 2
                        let binding = Binding<Double>(
                            get: { drafts[entry.hour] ?? entry.point?.score ?? defaultScore },
                            set: { drafts[entry.hour] = $0 }
                        )

                        Slider(value: binding, in: moodSettings.scoreRange, step: 1)

                        Text("\(Int(binding.wrappedValue))")
                            .font(.subheadline.bold().monospacedDigit())
                            .frame(width: 28, alignment: .trailing)
                    }
                    .listRowBackground(entry.point != nil ? Color.accentColor.opacity(0.08) : Color.clear)
                }
            }
            .navigationTitle("編輯今日心情")
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

    // MARK: - Data

    private var entries: [(hour: Date, point: MoodPoint?)] {
        let range = displayRange()
        return history.hourlyEntries(in: range.start...range.end)
    }

    private func displayRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let today8 = calendar.date(byAdding: .hour, value: 8, to: startOfDay)!

        let start: Date = (now < today8)
            ? calendar.date(byAdding: .day, value: -1, to: today8)!
            : today8

        // 到上一個小時為止（因為要過完一個小時才能紀錄）
        let currentHour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        let previousHour = calendar.date(byAdding: .hour, value: -1, to: currentHour) ?? currentHour
        return (start, max(start, previousHour))
    }

    private func loadDrafts() {
        for entry in entries {
            if let point = entry.point {
                drafts[entry.hour] = point.score
            }
        }
    }

    private func save() {
        for (hour, score) in drafts {
            history.addOrUpdate(score: score, forHour: hour)
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
