import SwiftUI

enum RecurringFrequency: String, CaseIterable, Identifiable {
    case none = "不重複"
    case daily = "每天"
    case weekly = "每週"
    case biweekly = "每兩週"
    case monthly = "每月"

    var id: String { rawValue }
}

struct AddCalendarEventView: View {
    @ObservedObject var store: CalendarStore
    let calendar: Calendar

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var start: Date = .now
    @State private var end: Date = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
    @State private var frequency: RecurringFrequency = .none
    @State private var repeatCount: Int = 12

    var body: some View {
        NavigationStack {
            Form {
                Section("事件") {
                    TextField("標題", text: $title)
                }

                Section("時間") {
                    DatePicker("開始", selection: $start, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("結束", selection: $end, displayedComponents: [.date, .hourAndMinute])
                }

                Section {
                    Picker("重複", selection: $frequency) {
                        ForEach(RecurringFrequency.allCases) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }

                    if frequency != .none {
                        Stepper("重複 \(repeatCount) 次", value: $repeatCount, in: 2...52)
                    }
                } footer: {
                    if frequency != .none {
                        Text("將自動建立 \(repeatCount) 次\(frequency.rawValue)的重複行程")
                    }
                }
            }
            .navigationTitle("新增事件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("加入") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        guard end >= start else { return }

                        Task {
                            await store.add(
                                title: trimmed,
                                start: start,
                                end: end,
                                frequency: frequency,
                                repeatCount: repeatCount
                            )
                            dismiss()
                        }
                    }
                }
            }
            .onChange(of: start) { _, newValue in
                if end < newValue {
                    end = calendar.date(byAdding: .hour, value: 1, to: newValue) ?? newValue
                }
            }
        }
    }
}
