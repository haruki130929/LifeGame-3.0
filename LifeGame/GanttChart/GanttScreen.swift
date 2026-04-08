import SwiftUI

struct GanttScreen: View {
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todoStore: TodoQuadrantStore
    @EnvironmentObject private var theme: ThemeStore

    @StateObject private var ganttStore = GanttStore()
    @State private var showAddMilestone = false
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // 時間尺度切換
            Picker("", selection: $ganttStore.timeScale) {
                ForEach(GanttTimeScale.allCases, id: \.self) { scale in
                    Text(scale.rawValue).tag(scale)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)

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
            .padding(.vertical, 10)

            // 圖例
            HStack(spacing: 12) {
                legendDot(color: "33A6B8", label: "行事曆")
                legendDot(color: "5B8DEF", label: "待辦")
                if ganttStore.showBuffer {
                    legendBuffer(label: "緩衝")
                }
                legendMilestone(label: "里程碑")
                Spacer()
                Button {
                    ganttStore.jumpToToday()
                } label: {
                    Text("今天")
                        .font(.caption)
                        .foregroundStyle(theme.accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Divider()

            // 甘特圖
            GanttChartView(
                items: ganttStore.buildItems(from: calendarStore, todoStore: todoStore),
                milestones: ganttStore.visibleMilestones(),
                timeScale: ganttStore.timeScale,
                dateRange: ganttStore.visibleDateRange
            )
        }
        .navigationTitle("甘特圖")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showAddMilestone = true
                    } label: {
                        Label("新增里程碑", systemImage: "diamond")
                    }

                    Toggle(isOn: $ganttStore.showBuffer) {
                        Label("顯示緩衝", systemImage: "clock.badge.questionmark")
                    }

                    if ganttStore.showBuffer {
                        Menu("緩衝比例") {
                            ForEach([10, 15, 20], id: \.self) { pct in
                                Button {
                                    ganttStore.bufferPercent = Double(pct)
                                } label: {
                                    HStack {
                                        Text("\(pct)%")
                                        if Int(ganttStore.bufferPercent) == pct {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if !ganttStore.milestones.isEmpty {
                        Divider()
                        Menu("刪除里程碑") {
                            ForEach(ganttStore.milestones) { ms in
                                Button(role: .destructive) {
                                    ganttStore.deleteMilestone(ms)
                                } label: {
                                    Text(ms.title)
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddMilestone) {
            AddMilestoneSheet(ganttStore: ganttStore)
        }
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

    private func legendBuffer(label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                .foregroundStyle(.secondary)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func legendMilestone(label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "FF6B6B"))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 新增里程碑 Sheet

private struct AddMilestoneSheet: View {
    @ObservedObject var ganttStore: GanttStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date = Date()
    @FocusState private var titleFocused: Bool

    private let colorOptions = ["FF6B6B", "FFA94D", "51CF66", "339AF0", "CC5DE8"]

    @State private var selectedColor = "FF6B6B"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("里程碑名稱", text: $title)
                        .focused($titleFocused)
                }

                Section {
                    DatePicker("日期", selection: $date)
                }

                Section("顏色") {
                    HStack(spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.white, lineWidth: selectedColor == hex ? 3 : 0)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    titleFocused = true
                }
            }
        }
    }
}
