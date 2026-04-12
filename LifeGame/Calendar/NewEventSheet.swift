import SwiftUI

struct NewEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var calendarSettings: CalendarSettingsStore
    @EnvironmentObject private var theme: ThemeStore

    @State private var title: String = ""
    @State private var start: Date = Date()
    @State private var end: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var colorHex: String = "33A6B8"
    @State private var frequency: RecurringFrequency = .none
    @State private var repeatCount: Int = 12

    let onSave: (String, Date, Date, String, RecurringFrequency, Int) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("基本") {
                    TextField("標題", text: $title)
                    DatePicker("開始", selection: $start)
                    DatePicker("結束", selection: $end)
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

                Section("顏色") {
                    if !calendarSettings.colorPresets.isEmpty {
                        ForEach(calendarSettings.colorPresets) { preset in
                            Button {
                                colorHex = preset.colorHex
                                if title.isEmpty {
                                    title = preset.name
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: preset.colorHex))
                                        .frame(width: 24, height: 24)
                                    Text(preset.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if colorHex.uppercased() == preset.colorHex.uppercased() {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(theme.accentColor)
                                    }
                                }
                            }
                        }
                    }
                    CompactPaletteColorPicker(selectedHex: $colorHex)
                }
            }
            .navigationTitle("新增行程")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty else { return }
                        onSave(t, start, end, colorHex, frequency, repeatCount)
                        dismiss()
                    }
                }
            }
            .onChange(of: colorHex) { _, newHex in
                if let presetName = calendarSettings.presetName(for: newHex), title.isEmpty {
                    title = presetName
                }
            }
        }
    }
}

struct EditEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var calendarSettings: CalendarSettingsStore
    @EnvironmentObject private var theme: ThemeStore

    let event: CalendarEvent
    let onSave: (String, Date, Date, String) -> Void
    var onDelete: (() -> Void)? = nil

    @State private var title: String
    @State private var start: Date
    @State private var end: Date
    @State private var colorHex: String
    @State private var showDeleteConfirmation = false

    init(event: CalendarEvent, onSave: @escaping (String, Date, Date, String) -> Void, onDelete: (() -> Void)? = nil) {
        self.event = event
        self.onSave = onSave
        self.onDelete = onDelete
        _title = State(initialValue: event.title)
        _start = State(initialValue: event.start)
        _end = State(initialValue: event.end)
        _colorHex = State(initialValue: event.colorHex)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本") {
                    TextField("標題", text: $title)
                    DatePicker("開始", selection: $start)
                    DatePicker("結束", selection: $end)
                }

                Section("顏色") {
                    if !calendarSettings.colorPresets.isEmpty {
                        ForEach(calendarSettings.colorPresets) { preset in
                            Button {
                                colorHex = preset.colorHex
                            } label: {
                                HStack(spacing: 10) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: preset.colorHex))
                                        .frame(width: 24, height: 24)
                                    Text(preset.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if colorHex.uppercased() == preset.colorHex.uppercased() {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(theme.accentColor)
                                    }
                                }
                            }
                        }
                    }
                    CompactPaletteColorPicker(selectedHex: $colorHex)
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("刪除這個行程", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("編輯行程")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty else { return }
                        onSave(t, start, end, colorHex)
                        dismiss()
                    }
                }
            }
            .confirmationDialog("確定要刪除「\(event.title)」嗎？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("刪除", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            }
        }
    }
}
