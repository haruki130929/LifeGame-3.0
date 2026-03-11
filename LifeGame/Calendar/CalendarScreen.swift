import SwiftUI

struct CalendarScreen: View {
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var fab: FabStore
    @StateObject private var todoStore = TodoQuadrantStore()

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
                        .map { UrgentImportantTask(title: $0.title) }
                )
                .padding(.horizontal, 12)
                
                // ✅ 當日清單
                dayList
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
            case .jumpToToday:
                fab.route = nil
                withAnimation {
                    monthOffset = 0
                    selected = Date()
                }
            default:
                break
            }
        }

        // ✅ 編輯行程
        .sheet(isPresented: $showEditor) {
            if let e = editingEvent {
                EditEventSheet(event: e) { newTitle, newStart, newEnd in
                    // 找到原本事件，更新
                    if let idx = calendarStore.events.firstIndex(where: { $0.id == e.id }) {
                        calendarStore.events[idx] = CalendarEvent(id: e.id, title: newTitle, start: newStart, end: newEnd)
                    }
                }
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
    
    // MARK: - Day list
    private var dayList: some View {
        let events = calendarStore.events(on: selected, calendar: cal)
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(dayTitle(selected))
                    .font(.headline)
                Spacer()
                Text("共 \(events.count) 筆")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if events.isEmpty {
                Text("今天沒有行程")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(events) { e in
                        Button {
                            editingEvent = e
                            showEditor = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(e.title)
                                        .font(.headline)
                                    Text(timeRangeText(e))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private func dayTitle(_ d: Date) -> String {
        let y = cal.component(.year, from: d)
        let m = cal.component(.month, from: d)
        let day = cal.component(.day, from: d)
        return "\(y)/\(m)/\(day)"
    }
    
    private func timeRangeText(_ e: CalendarEvent) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "\(f.string(from: e.start)) – \(f.string(from: e.end))"
    }
}
