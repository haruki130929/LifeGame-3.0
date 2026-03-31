import SwiftUI

struct WeeklyScheduleEditorView: View {
    @EnvironmentObject private var scheduleStore: WeeklyScheduleStore
    @State private var selectedDay: Weekday = .monday
    @State private var showAddSheet = false
    @State private var editingItem: RingItem?

    var body: some View {
        VStack(spacing: 0) {
            // 星期選擇器
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Weekday.allCases) { day in
                        Button {
                            selectedDay = day
                        } label: {
                            Text(day.shortTitle)
                                .font(.system(size: 15, weight: selectedDay == day ? .bold : .regular))
                                .foregroundStyle(selectedDay == day ? .white : .primary)
                                .frame(width: 40, height: 40)
                                .background(
                                    selectedDay == day
                                        ? Color.accentColor
                                        : Color(.tertiarySystemFill),
                                    in: Circle()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }

            Divider()

            // 時段列表
            let items = scheduleStore.items(for: selectedDay)
            if items.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("\(selectedDay.title)尚未設定課表")
                        .foregroundStyle(.secondary)
                    Button("新增時段") {
                        showAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
            } else {
                List {
                    ForEach(items) { item in
                        Button {
                            editingItem = item
                        } label: {
                            ScheduleItemRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        scheduleStore.removeItems(at: offsets, for: selectedDay)
                    }

                    Button {
                        showAddSheet = true
                    } label: {
                        Label("新增時段", systemImage: "plus")
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("課表設定")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddRingItemSheet(defaultStartMinute: defaultStart()) { draft in
                let item = RingItem(
                    id: UUID(),
                    slot: draft.slot,
                    startMinute: draft.startMinute,
                    endMinute: draft.endMinute,
                    title: draft.title,
                    icon: draft.icon,
                    colorHex: draft.colorHex,
                    hpCost: draft.hpCost,
                    fpCost: draft.fpCost
                )
                scheduleStore.addItem(item, for: selectedDay)
            }
        }
        .sheet(item: $editingItem) { item in
            ScheduleEditSheet(item: item, weekday: selectedDay)
                .environmentObject(scheduleStore)
        }
    }

    private func defaultStart() -> Int {
        let items = scheduleStore.items(for: selectedDay)
        if let last = items.last {
            return last.endMinute
        }
        return 9 * 60
    }
}

// MARK: - Schedule Item Row

private struct ScheduleItemRow: View {
    let item: RingItem

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: item.colorHex) ?? .blue)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body.weight(.medium))
                Text("\(minuteToTime(item.startMinute))～\(minuteToTime(item.endMinute))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if item.hpCost > 0 || item.fpCost > 0 {
                HStack(spacing: 8) {
                    if item.hpCost > 0 {
                        Text("HP -\(item.hpCost)")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                    if item.fpCost > 0 {
                        Text("FP -\(item.fpCost)")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func minuteToTime(_ m: Int) -> String {
        let h = m / 60
        let min = m % 60
        return String(format: "%02d:%02d", h, min)
    }
}

// MARK: - Schedule Edit Sheet

private struct ScheduleEditSheet: View {
    let item: RingItem
    let weekday: Weekday
    @EnvironmentObject private var scheduleStore: WeeklyScheduleStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var icon: String
    @State private var colorHex: String
    @State private var startMinute: Int
    @State private var endMinute: Int
    @State private var hpCost: Int
    @State private var fpCost: Int
    @State private var showDeleteConfirm = false

    init(item: RingItem, weekday: Weekday) {
        self.item = item
        self.weekday = weekday
        _title = State(initialValue: item.title)
        _icon = State(initialValue: item.icon)
        _colorHex = State(initialValue: item.colorHex)
        _startMinute = State(initialValue: item.startMinute)
        _endMinute = State(initialValue: item.endMinute)
        _hpCost = State(initialValue: item.hpCost)
        _fpCost = State(initialValue: item.fpCost)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本資訊") {
                    TextField("名稱", text: $title)

                    DisclosureGroup {
                        RingIconPicker(selected: $icon)
                    } label: {
                        HStack {
                            Text("圖示")
                            Spacer()
                            Image(systemName: icon)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("時間") {
                    TimePicker(label: "開始", minute: $startMinute)
                    TimePicker(label: "結束", minute: $endMinute)
                }

                Section("顏色") {
                    CompactPaletteColorPicker(selectedHex: $colorHex)
                }

                Section("消耗") {
                    Stepper("HP -\(hpCost)", value: $hpCost, in: 0...100, step: 5)
                    Stepper("FP -\(fpCost)", value: $fpCost, in: 0...100, step: 5)
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("刪除此時段")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("編輯時段")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        var updated = item
                        updated.title = title
                        updated.icon = icon
                        updated.colorHex = colorHex
                        updated.startMinute = startMinute
                        updated.endMinute = endMinute
                        updated.hpCost = hpCost
                        updated.fpCost = fpCost
                        scheduleStore.updateItem(updated, for: weekday)
                        dismiss()
                    }
                }
            }
            .confirmationDialog("確定要刪除「\(title)」嗎？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("刪除", role: .destructive) {
                    scheduleStore.removeItem(id: item.id, for: weekday)
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            }
        }
    }
}

// MARK: - Time Picker Helper

private struct TimePicker: View {
    let label: String
    @Binding var minute: Int

    private var hour: Int { minute / 60 }
    private var min: Int { minute % 60 }

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Picker("時", selection: Binding(
                get: { hour },
                set: { minute = $0 * 60 + min }
            )) {
                ForEach(0..<24, id: \.self) { h in
                    Text("\(h)時").tag(h)
                }
            }
            .pickerStyle(.menu)

            Picker("分", selection: Binding(
                get: { min / 10 },
                set: { minute = hour * 60 + $0 * 10 }
            )) {
                ForEach(0..<6, id: \.self) { m in
                    Text("\(m * 10)分").tag(m)
                }
            }
            .pickerStyle(.menu)
        }
    }
}
