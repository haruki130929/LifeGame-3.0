import SwiftUI

struct TomorrowRingDetailView: View {
    @Binding var plan: TomorrowRingPlan

    @EnvironmentObject private var fab: FabStore
    @EnvironmentObject private var game: LifeGame
    @EnvironmentObject private var scheduleStore: WeeklyScheduleStore

    @State private var isPresentingAdd = false
    @State private var editingItem: RingItem? = nil
    @State private var ringSelectedID: UUID? = nil
    @State private var showScheduleEditor = false
    @State private var selectedDay: Weekday = Weekday.today

    /// 其他天的課表預覽 plan（非今天時使用）
    @State private var previewPlan = TomorrowRingPlan(date: Date(), items: [])

    /// 目前是否正在看今天
    private var isToday: Bool { selectedDay == Weekday.today }

    /// 顯示用的 plan（今天 = 真正的 plan，其他天 = 課表預覽）
    private var displayPlan: Binding<TomorrowRingPlan> {
        isToday ? $plan : $previewPlan
    }

    /// 顯示用的時段列表
    private var displayItems: [RingItem] {
        isToday ? plan.items : previewPlan.items
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── 星期選擇器 ──
            daySelectorBar

            Group {
                if AppLayout.isIPad {
                    HStack(alignment: .top, spacing: 0) {
                        ringSection
                        listSection
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ringSection
                                .frame(height: 360)
                            phoneListSection
                        }
                    }
                }
            }
        }
        // ✅ 點擊畫面任何地方取消選取
        .simultaneousGesture(
            TapGesture().onEnded {
                if ringSelectedID != nil {
                    ringSelectedID = nil
                }
            }
        )
        .navigationTitle("時間圓環")
        .navigationBarTitleDisplayMode(.inline)
        .featureTutorial(.timeRing)

        // ── 進入時同步課表 & 切換 FAB 選單 ──
        .onAppear {
            syncScheduleToPlan()
            fab.apply(context: .feature(.tomorrowRing))
        }
        .onDisappear {
            fab.popActions()
        }

        // ── 切換星期時更新預覽 ──
        .onChange(of: selectedDay) { _, newDay in
            ringSelectedID = nil
            if newDay == Weekday.today {
                syncScheduleToPlan()
            } else {
                loadPreview(for: newDay)
            }
        }

        // ── 監聯 FAB route，觸發對應動作 ──
        .onChange(of: fab.route) { _, newRoute in
            switch newRoute {
            case .addRingItem:
                fab.route = nil
                if isToday { isPresentingAdd = true }
            case .editSchedule:
                fab.route = nil
                showScheduleEditor = true
            default:
                break
            }
        }

        .sheet(isPresented: $isPresentingAdd) {
            AddRingItemSheet(defaultStartMinute: defaultNewStartMinute()) { draft in
                let new = RingItem(
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
                plan.items.append(new)
                plan.items.sort { $0.startMinute < $1.startMinute }
            }
        }

        .sheet(item: $editingItem) { item in
            EditRingItemSheet(item: item) { updated in
                if isToday {
                    if let i = plan.items.firstIndex(where: { $0.id == updated.id }) {
                        plan.items[i] = updated
                        plan.items.sort { $0.startMinute < $1.startMinute }
                    }
                }
            } onDelete: {
                if isToday {
                    plan.items.removeAll { $0.id == item.id }
                }
            }
        }
        .sheet(isPresented: $showScheduleEditor, onDismiss: {
            if isToday {
                syncScheduleToPlan()
            } else {
                loadPreview(for: selectedDay)
            }
        }) {
            NavigationStack {
                WeeklyScheduleEditorView()
            }
        }
    }

    // MARK: - 星期選擇器

    private var daySelectorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Weekday.allCases) { day in
                    let isCurrent = day == selectedDay
                    let isDayToday = day == Weekday.today

                    Button {
                        selectedDay = day
                    } label: {
                        VStack(spacing: 2) {
                            Text(day.shortTitle)
                                .font(.system(size: 14, weight: isCurrent ? .bold : .regular))

                            if isDayToday {
                                Circle()
                                    .fill(isCurrent ? .white : Color.accentColor)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .foregroundStyle(isCurrent ? .white : .primary)
                        .frame(width: 38, height: 44)
                        .background(
                            isCurrent ? Color.accentColor : Color(.tertiarySystemFill),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Sections

    private var ringSection: some View {
        TomorrowRingView(
            plan: displayPlan,
            selectedItemID: $ringSelectedID,
            mode: .detail,
            gameHP: isToday ? game.hp : nil,
            gameFP: isToday ? game.fp : nil
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                listHeader

                if displayItems.isEmpty {
                    emptyPlaceholder
                } else {
                    ForEach(displayItems) { item in
                        RingRow(item: item) {
                            if isToday {
                                editingItem = item
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 80)
        }
        .frame(maxWidth: .infinity)
    }

    /// iPhone 用：不包 ScrollView（外層已有）
    private var phoneListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            listHeader

            if displayItems.isEmpty {
                emptyPlaceholder
            } else {
                ForEach(displayItems) { item in
                    RingRow(item: item) {
                        if isToday {
                            editingItem = item
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 80)
    }

    @ViewBuilder
    private var listHeader: some View {
        HStack {
            Text(isToday ? "時段" : "\(selectedDay.title)課表")
                .font(.headline)
            Spacer()
            if !isToday {
                Text("課表預覽")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Empty

    private var emptyPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text(isToday ? "還沒有任何時段" : "\(selectedDay.title)尚未設定課表")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if isToday {
                Text("點右下角「＋」新增第一個時段")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Button("編輯課表") {
                    showScheduleEditor = true
                }
                .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - 課表同步

    /// 把今天的課表時段同步到圓環 plan
    private func syncScheduleToPlan() {
        scheduleStore.loadIfNeeded()
        let today = Weekday.today
        let scheduleItems = scheduleStore.items(for: today)

        plan.items.removeAll { $0.isFromSchedule }

        for template in scheduleItems {
            var newItem = template
            newItem.id = UUID()
            newItem.isFromSchedule = true
            plan.items.append(newItem)
        }

        plan.items.sort { $0.startMinute < $1.startMinute }
    }

    /// 載入其他天的課表作為預覽
    private func loadPreview(for day: Weekday) {
        scheduleStore.loadIfNeeded()
        let items = scheduleStore.items(for: day)
        var previewItems: [RingItem] = []
        for template in items {
            var item = template
            item.isFromSchedule = true
            previewItems.append(item)
        }
        previewItems.sort { $0.startMinute < $1.startMinute }
        previewPlan = TomorrowRingPlan(date: Date(), items: previewItems)
    }

    // MARK: - Helpers

    private func defaultNewStartMinute() -> Int {
        let fallback = 9 * 60
        guard let last = plan.items.max(by: { $0.endMinute < $1.endMinute }) else { return fallback }
        return last.endMinute
    }
}

// MARK: - 編輯時段 Sheet

struct EditRingItemSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var item: RingItem
    let onSave: (RingItem) -> Void
    let onDelete: () -> Void

    init(item: RingItem, onSave: @escaping (RingItem) -> Void, onDelete: @escaping () -> Void) {
        _item = State(initialValue: item)
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本") {
                    TextField("名稱", text: $item.title)

                    DisclosureGroup {
                        RingIconPicker(selected: $item.icon)
                    } label: {
                        HStack {
                            Text("圖示")
                            Spacer()
                            Image(systemName: item.icon)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("顏色") {
                    CompactPaletteColorPicker(selectedHex: $item.colorHex)
                }

                Section("時間") {
                    timePickerRow(title: "開始", minute: $item.startMinute)
                    timePickerRow(title: "結束", minute: $item.endMinute)
                }

                Section("消耗") {
                    Stepper("HP 消耗：\(item.hpCost)P", value: $item.hpCost, in: 0...100, step: 5)
                    Stepper("FP 消耗：\(item.fpCost)P", value: $item.fpCost, in: 0...100, step: 5)
                }

                Section {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Label("刪除此時段", systemImage: "trash")
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
                        onSave(item)
                        dismiss()
                    }
                }
            }
        }
    }

    private func colorRow(_ name: String, _ hex: String) -> some View {
        Button {
            item.colorHex = hex
        } label: {
            HStack {
                Circle().fill(Color(hex: hex)).frame(width: 10, height: 10)
                Text(name)
                Spacer()
                if item.colorHex == hex {
                    Image(systemName: "checkmark").foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
    }

    private func timePickerRow(title: String, minute: Binding<Int>) -> some View {
        let binding = Binding<Date>(
            get: { dateFromMinute(minute.wrappedValue) },
            set: { newDate in
                let m = minuteFromDate(newDate)
                minute.wrappedValue = snap(m, step: 10)
            }
        )
        return DatePicker(title, selection: binding, displayedComponents: .hourAndMinute)
            .datePickerStyle(.compact)
    }
}

// MARK: - RingRow

struct RingRow: View {
    let item: RingItem
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: item.colorHex).opacity(0.9))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(item.title)
                        .font(.footnote)
                        .lineLimit(1)
                    if item.isFromSchedule {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("\(minuteText(item.startMinute)) 〜 \(minuteText(item.endMinute))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Text(durationText(start: item.startMinute, end: item.endMinute))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("編輯")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func durationText(start: Int, end: Int) -> String {
        let total = positiveDuration(from: start, to: end)
        let h = total / 60
        let m = total % 60
        if h > 0 {
            return String(format: "%dh %02dm", h, m)
        } else {
            return String(format: "%dm", m)
        }
    }

    private func positiveDuration(from start: Int, to end: Int) -> Int {
        let d = end - start
        return d >= 0 ? d : (d + 1440)
    }

    private func minuteText(_ m: Int) -> String {
        let mm = (m % 1440 + 1440) % 1440
        return String(format: "%02d:%02d", mm / 60, mm % 60)
    }
}

// MARK: - Shared helpers

private func dateFromMinute(_ minute: Int) -> Date {
    var comps = DateComponents()
    comps.year = 2000; comps.month = 1; comps.day = 1
    comps.hour = minute / 60; comps.minute = minute % 60
    return Calendar.current.date(from: comps) ?? Date()
}

private func minuteFromDate(_ date: Date) -> Int {
    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
    return ((comps.hour ?? 0) * 60 + (comps.minute ?? 0)) % 1440
}

private func snap(_ m: Int, step: Int) -> Int {
    let snapped = Int(round(Double(m) / Double(step))) * step
    return min(max(snapped, 0), 1440 - step)
}
