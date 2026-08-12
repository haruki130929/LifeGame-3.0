import SwiftUI

struct CalendarScreen: View {
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var fab: FabStore
    @EnvironmentObject private var todoStore: TodoQuadrantStore

    // MARK: - State
    @State private var monthOffset: Int = 0
    @State private var selected: Date = Date()

    @State private var showNewEvent: Bool = false
    @State private var editingEvent: CalendarEvent? = nil
    @State private var isSyncing = false
    @State private var syncAlert: String?
    @AppStorage(CalendarStore.autoSyncKey) private var autoSyncEnabled = false

    private let cal = Calendar.current
    
    private var monthDate: Date {
        cal.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {

                CalendarCard(
                    size: .large,
                    monthDate: monthDate,
                    ranges: rangesForMonth,
                    onPrevMonth: { monthOffset -= 1 },
                    onNextMonth: { monthOffset += 1 },
                    urgentImportantTasks: todoStore.items(in: .importantUrgent)
                        .filter { !$0.isDone }
                        .map { UrgentImportantTask(title: $0.title) },
                    showsEventTitles: true
                )
                .padding(.horizontal, 12)

                // ✅ 今日行程
                todaySection
                    .padding(.horizontal, 12)

                // ✅ 當月行程
                monthEventSection
                    .padding(.horizontal, 12)
            }
            .padding(.vertical, 12)
        }
        .navigationTitle("行事曆")
        .navigationBarTitleDisplayMode(.inline)

        // ✅ 右上角同步按鈕（只在開啟自動同步時顯示）
        .toolbar {
            if autoSyncEnabled {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: runSync) {
                        if isSyncing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(isSyncing)
                    .accessibilityLabel("同步 Apple 行事曆")
                }
            }
        }
        .alert(syncAlert ?? "", isPresented: Binding(
            get: { syncAlert != nil },
            set: { if !$0 { syncAlert = nil } }
        )) {
            Button("好", role: .cancel) {}
        }

        // ✅ 新增行程
        .sheet(isPresented: $showNewEvent) {
            NewEventSheet { title, start, end, colorHex, frequency, repeatCount in
                Task {
                    await calendarStore.add(title: title, start: start, end: end, colorHex: colorHex, frequency: frequency, repeatCount: repeatCount)
                }
            }
        }
        
        // ── FAB 選單接入 ──
        .onAppear {
            fab.apply(context: .feature(.calendar))
        }
        .onDisappear {
            fab.popActions()
        }
        .onChange(of: fab.route) { _, newRoute in
            switch newRoute {
            case .addCalendarEvent:
                fab.route = nil
                showNewEvent = true
            case .syncAppleCalendar:
                fab.route = nil
                runSync()
            default:
                break
            }
        }

        // ✅ 編輯行程
        .sheet(item: $editingEvent) { e in
            EditEventSheet(event: e, onSave: { newTitle, newStart, newEnd, newColorHex in
                Task {
                    await calendarStore.update(e, title: newTitle, start: newStart, end: newEnd, colorHex: newColorHex)
                }
            }, onDelete: {
                calendarStore.delete(e)
            })
        }
    }
    
    // MARK: - 同步 Apple 行事曆（近期：過去 1 個月 ～ 未來 3 個月）
    private func runSync() {
        guard !isSyncing else { return }
        isSyncing = true
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .month, value: -1, to: today) ?? today
        let end = cal.date(byAdding: .month, value: 3, to: today) ?? today
        Task {
            let count = await calendarStore.syncFromAppleCalendar(start: start, end: end)
            isSyncing = false
            if count < 0 {
                syncAlert = String(localized: "需要行事曆權限，請到「設定 → LifeGame → 行事曆」開啟")
            } else {
                syncAlert = count > 0 ? String(localized: "已同步，新增 \(count) 筆行程") : String(localized: "已是最新，沒有新行程")
            }
        }
    }

    // MARK: - Ranges (月行程條)
    private var rangesForMonth: [CalendarRange] {
        CalendarRangeProvider().ranges(from: calendarStore.events, in: monthDate)
    }
    
    // MARK: - 今日行程

    private var todaySection: some View {
        let today = Date()
        let todayEvents = calendarStore.events(on: today, calendar: cal)

        return VStack(alignment: .leading, spacing: 10) {
            Text("今日")
                .font(.headline)

            if todayEvents.isEmpty {
                Text("今日尚未有安排")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(todayEvents) { e in
                        eventRow(e)
                    }
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - 當月行程

    private var monthEventSection: some View {
        let monthEvents = eventsForCurrentMonth()

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("當月行程")
                    .font(.headline)
                Spacer()
                Text("共 \(monthEvents.count) 筆")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if monthEvents.isEmpty {
                Text("本月沒有行程")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(monthEvents) { e in
                        eventRow(e)
                    }
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - 行程列

    private func eventRow(_ e: CalendarEvent) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: e.colorHex) ?? .cyan)
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(e.title)
                    .font(.headline)
                Text(eventDateTimeText(e))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                editingEvent = e
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func eventsForCurrentMonth() -> [CalendarEvent] {
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: monthDate)),
              let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) else {
            return []
        }
        return calendarStore.events
            .filter { $0.start >= monthStart && $0.start < monthEnd }
            .sorted { $0.start < $1.start }
    }
    
    private func eventDateTimeText(_ e: CalendarEvent) -> String {
        let df = DateFormatter()
        df.dateFormat = "M/d"
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        return "\(df.string(from: e.start)) \(tf.string(from: e.start)) – \(tf.string(from: e.end))"
    }
}
