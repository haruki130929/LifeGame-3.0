import SwiftUI

struct GanttScreen: View {
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todoStore: TodoQuadrantStore
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var fab: FabStore

    @StateObject private var ganttStore = GanttStore()
    @State private var showAddTask = false
    @State private var showAddMilestone = false
    @State private var showBufferSettings = false
    @State private var editingTask: GanttTask?
    @State private var addSubtaskParent: IdentifiableUUID?

    var body: some View {
        VStack(spacing: 0) {
            // 導航列
            HStack {
                Button { ganttStore.goBackward() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                }

                Spacer()

                Text(ganttStore.dateRangeLabel)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Button { ganttStore.goForward() } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 6)

            // 圖例
            legendRow

            Divider()

            // 甘特圖（內建日/週/月切換器在左上角）
            GanttChartView(
                items: ganttStore.buildItems(from: calendarStore, todoStore: todoStore),
                milestones: ganttStore.visibleMilestones(),
                timeScale: $ganttStore.timeScale,
                dateRange: ganttStore.visibleDateRange,
                onEditTask: { task in editingTask = task },
                onAddSubtask: { parentId in addSubtaskParent = IdentifiableUUID(parentId) },
                onDeleteTask: { task in ganttStore.deleteTask(task) },
                onToggleDone: { task in ganttStore.toggleTaskDone(task) },
                onResizeTask: { task, newStart, newEnd in
                    var updated = task
                    updated.start = newStart
                    updated.end = newEnd
                    if task.parentId != nil {
                        ganttStore.updateSubtaskAndRealign(updated)
                    } else {
                        ganttStore.updateTask(updated)
                    }
                }
            )
        }
        .navigationTitle("甘特圖")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fab.apply(context: .feature(.ganttChart))
        }
        .onDisappear {
            fab.popActions()
        }
        .onChange(of: fab.route) { _, newRoute in
            switch newRoute {
            case .addGanttTask:
                fab.route = nil
                showAddTask = true
            case .addMilestone:
                fab.route = nil
                showAddMilestone = true
            case .toggleBuffer:
                fab.route = nil
                showBufferSettings = true
            default:
                break
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddGanttTaskSheet(ganttStore: ganttStore)
        }
        .sheet(isPresented: $showAddMilestone) {
            AddMilestoneSheet(ganttStore: ganttStore)
        }
        .sheet(isPresented: $showBufferSettings) {
            BufferSettingsSheet(ganttStore: ganttStore)
        }
        .sheet(item: $editingTask) { task in
            EditGanttTaskSheet(ganttStore: ganttStore, task: task) { parentId in
                addSubtaskParent = IdentifiableUUID(parentId)
            }
        }
        .sheet(item: $addSubtaskParent) { wrapper in
            AddSubtaskSheet(ganttStore: ganttStore, parentId: wrapper.value)
        }
    }

    // MARK: - Legend

    private var legendRow: some View {
        let items = ganttStore.buildItems(from: calendarStore, todoStore: todoStore)
        let hasCustom = items.contains { $0.source == .custom || $0.source == .parentTask }
        let hasCalendar = items.contains { $0.source == .calendar }
        let hasTodo = items.contains { $0.source == .todo }

        return HStack(spacing: 10) {
            if hasCustom { legendDot(color: "339AF0", label: "任務") }
            if hasCalendar { legendDot(color: "33A6B8", label: "行事曆") }
            if hasTodo { legendDot(color: "5B8DEF", label: "待辦") }
            Spacer()
            Button { ganttStore.jumpToToday() } label: {
                Text("今天")
                    .font(.caption)
                    .foregroundStyle(theme.accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    private func legendDot(color: String, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: color))
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 新增任務 Sheet

private struct AddGanttTaskSheet: View {
    @ObservedObject var ganttStore: GanttStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var selectedColor = "339AF0"
    @FocusState private var titleFocused: Bool

    private let colorOptions = ["339AF0", "51CF66", "FFA94D", "FF6B6B", "CC5DE8", "20C997", "FAB005"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("任務名稱", text: $title)
                        .focused($titleFocused)
                }

                Section {
                    DatePicker("開始日期", selection: $startDate, displayedComponents: .date)
                    DatePicker("結束日期", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                colorSection
            }
            .navigationTitle("新增任務")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        ganttStore.addTask(title: title, start: startDate, end: endDate, colorHex: selectedColor)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    titleFocused = true
                }
            }
        }
    }

    private var colorSection: some View {
        Section("顏色") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(colorOptions, id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle().strokeBorder(.white, lineWidth: selectedColor == hex ? 3 : 0)
                        )
                        .onTapGesture { selectedColor = hex }
                }
            }
        }
    }
}

// MARK: - 編輯任務 Sheet

private struct EditGanttTaskSheet: View {
    @ObservedObject var ganttStore: GanttStore
    let task: GanttTask
    var onAddSubtask: ((UUID) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var selectedColor: String = "339AF0"

    private let colorOptions = ["339AF0", "51CF66", "FFA94D", "FF6B6B", "CC5DE8", "20C997", "FAB005"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("任務名稱", text: $title)
                }

                Section {
                    DatePicker("開始日期", selection: $startDate, displayedComponents: .date)
                    DatePicker("結束日期", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                Section("顏色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle().strokeBorder(.white, lineWidth: selectedColor == hex ? 3 : 0)
                                )
                                .onTapGesture { selectedColor = hex }
                        }
                    }
                }

                // 操作區
                Section {
                    // 新增子任務（只有頂層任務）
                    if task.parentId == nil {
                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onAddSubtask?(task.id)
                            }
                        } label: {
                            Label("新增子任務", systemImage: "plus.circle")
                        }
                    }

                    // 標為完成/未完成
                    Button {
                        ganttStore.toggleTaskDone(task)
                        dismiss()
                    } label: {
                        Label(task.isDone ? "標為未完成" : "標為完成",
                              systemImage: task.isDone ? "circle" : "checkmark.circle.fill")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        ganttStore.deleteTask(task)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Label("刪除任務", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("編輯任務")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        var updated = task
                        updated.title = title
                        updated.start = startDate
                        updated.end = endDate
                        updated.colorHex = selectedColor
                        ganttStore.updateTask(updated)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                title = task.title
                startDate = task.start
                endDate = task.end
                selectedColor = task.colorHex
            }
        }
    }
}

// MARK: - 新增里程碑 Sheet

private struct AddMilestoneSheet: View {
    @ObservedObject var ganttStore: GanttStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date = Date()
    @State private var selectedColor = "BE4BDB"
    @FocusState private var titleFocused: Bool

    private let colorOptions = ["BE4BDB", "F59F00", "20C997", "E8590C", "AE3EC9"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("里程碑名稱", text: $title)
                        .focused($titleFocused)
                }
                Section {
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }
                Section("顏色") {
                    HStack(spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().strokeBorder(.white, lineWidth: selectedColor == hex ? 3 : 0)
                                )
                                .onTapGesture { selectedColor = hex }
                        }
                    }
                }
            }
            .navigationTitle("新增里程碑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        ganttStore.addMilestone(title: title, date: date, colorHex: selectedColor)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { titleFocused = true }
            }
        }
    }
}

// MARK: - 緩衝設定 Sheet

private struct BufferSettingsSheet: View {
    @ObservedObject var ganttStore: GanttStore
    @Environment(\.dismiss) private var dismiss

    private let percentOptions = [10, 15, 20]

    var body: some View {
        NavigationStack {
            Form {
                bufferToggleSection
                if ganttStore.showBuffer {
                    bufferPercentSection
                }
            }
            .navigationTitle("緩衝設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private var bufferToggleSection: some View {
        Section {
            Toggle("顯示緩衝", isOn: $ganttStore.showBuffer)
        }
    }

    private var bufferPercentSection: some View {
        Section("緩衝比例") {
            ForEach(percentOptions, id: \.self) { pct in
                bufferPercentRow(pct)
            }
        }
    }

    private func bufferPercentRow(_ pct: Int) -> some View {
        let isSelected = Int(ganttStore.bufferPercent) == pct
        return Button {
            ganttStore.bufferPercent = Double(pct)
        } label: {
            HStack {
                Text("\(pct)%").foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}

// MARK: - UUID Identifiable wrapper

struct IdentifiableUUID: Identifiable {
    let id: UUID
    let value: UUID
    init(_ uuid: UUID) { self.id = uuid; self.value = uuid }
}

// MARK: - 新增子任務 Sheet

private struct AddSubtaskSheet: View {
    @ObservedObject var ganttStore: GanttStore
    let parentId: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var duration: Int = 3  // 天
    @State private var isSequential = true
    @FocusState private var titleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("子任務名稱", text: $title)
                        .focused($titleFocused)
                }

                Section {
                    Stepper("持續天數：\(duration) 天", value: $duration, in: 1...90)
                }

                Section {
                    Toggle("做完上一個才能做這個", isOn: $isSequential)
                } footer: {
                    Text("開啟後，此子任務會自動排在上一個子任務結束後開始")
                }
            }
            .navigationTitle("新增子任務")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        ganttStore.addSubtask(
                            title: title,
                            parentId: parentId,
                            duration: TimeInterval(duration) * 86400,
                            isSequential: isSequential
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { titleFocused = true }
            }
        }
    }
}
