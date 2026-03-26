import SwiftUI

struct CalendarScreen: View {
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var fab: FabStore
    @EnvironmentObject private var todoStore: TodoQuadrantStore

    // MARK: - State
    @State private var monthOffset: Int = 0
    @State private var selected: Date = Date()

    @State private var showNewEvent: Bool = false
    @State private var showEditor: Bool = false
    @State private var editingEvent: CalendarEvent? = nil
    
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
                    onTapEvent: { eventId in
                        if let event = calendarStore.events.first(where: { $0.id == eventId }) {
                            editingEvent = event
                            showEditor = true
                        }
                    }
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
        
        // ✅ 新增行程
        .sheet(isPresented: $showNewEvent) {
            NewEventSheet { title, start, end in
                Task {
                    await calendarStore.add(title: title, start: start, end: end)
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
            default:
                break
            }
        }

        // ✅ 編輯行程
        .sheet(isPresented: $showEditor) {
            if let e = editingEvent {
                EditEventSheet(event: e, onSave: { newTitle, newStart, newEnd in
                    // 找到原本事件，更新
                    if let idx = calendarStore.events.firstIndex(where: { $0.id == e.id }) {
                        calendarStore.events[idx] = CalendarEvent(id: e.id, title: newTitle, start: newStart, end: newEnd)
                    }
                }, onDelete: {
                    calendarStore.events.removeAll { $0.id == e.id }
                })
            } else {
                Text("沒有選到要編輯的行程")
                    .padding()
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
        HStack {
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
                showEditor = true
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
