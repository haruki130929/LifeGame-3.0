import SwiftUI

struct TomorrowRingDetailView: View {
    @Binding var plan: TomorrowRingPlan

    @EnvironmentObject private var fab: FabStore
    @EnvironmentObject private var game: LifeGame

    @State private var isPresentingAdd = false
    @State private var editingItem: RingItem? = nil
    @State private var ringSelectedID: UUID? = nil
    @State private var showScheduleEditor = false

    var body: some View {
        Group {
            if AppLayout.isIPad {
                // iPad：左右並排
                HStack(alignment: .top, spacing: 0) {
                    ringSection
                    listSection
                }
            } else {
                // iPhone：上下排列（圓環在上，時段列表在下）
                ScrollView {
                    VStack(spacing: 0) {
                        ringSection
                            .frame(height: 360)
                        phoneListSection
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

        // ── 進入/離開時切換 FAB 選單 ──
        .onAppear {
            fab.apply(context: .feature(.tomorrowRing))
        }
        .onDisappear {
            fab.popActions()
        }

        // ── 監聽 FAB route，觸發對應動作 ──
        .onChange(of: fab.route) { _, newRoute in
            switch newRoute {
            case .addRingItem:
                fab.route = nil
                isPresentingAdd = true
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
                if let i = plan.items.firstIndex(where: { $0.id == updated.id }) {
                    plan.items[i] = updated
                    plan.items.sort { $0.startMinute < $1.startMinute }
                }
            } onDelete: {
                plan.items.removeAll { $0.id == item.id }
            }
        }
        .sheet(isPresented: $showScheduleEditor) {
            NavigationStack {
                WeeklyScheduleEditorView()
            }
        }
    }

    // MARK: - Sections

    private var ringSection: some View {
        TomorrowRingView(
            plan: $plan,
            selectedItemID: $ringSelectedID,
            mode: .detail,
            gameHP: game.hp,
            gameFP: game.fp
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("時段")
                    .font(.headline)

                if plan.items.isEmpty {
                    emptyPlaceholder
                } else {
                    ForEach(plan.items) { item in
                        RingRow(item: item) {
                            editingItem = item
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
            Text("時段")
                .font(.headline)

            if plan.items.isEmpty {
                emptyPlaceholder
            } else {
                ForEach(plan.items) { item in
                    RingRow(item: item) {
                        editingItem = item
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 80)
    }

    // MARK: - Empty

    private var emptyPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("還沒有任何時段")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("點右下角「＋」新增第一個時段")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
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

                    Picker("圖示", selection: $item.icon) {
                        Label("時鐘", systemImage: "clock").tag("clock")
                        Label("書本", systemImage: "book").tag("book")
                        Label("走路", systemImage: "figure.walk").tag("figure.walk")
                        Label("用餐", systemImage: "fork.knife").tag("fork.knife")
                        Label("睡眠", systemImage: "moon").tag("moon")
                    }
                }

                Section("顏色") {
                    colorRow("藍", "4DA3FF")
                    colorRow("綠", "3AD29F")
                    colorRow("黃", "F6C445")
                    colorRow("紫", "9B7BFF")
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
