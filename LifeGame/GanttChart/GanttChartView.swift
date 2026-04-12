import SwiftUI

/// 甘特圖核心視圖 — 左側任務列表 + 右側橫向捲動時間軸
struct GanttChartView: View {
    let items: [GanttItem]
    let milestones: [GanttMilestone]
    @Binding var timeScale: GanttTimeScale
    let dateRange: ClosedRange<Date>
    var onEditTask: ((GanttTask) -> Void)? = nil
    var onAddSubtask: ((UUID) -> Void)? = nil
    var onDeleteTask: ((GanttTask) -> Void)? = nil
    var onToggleDone: ((GanttTask) -> Void)? = nil
    var onResizeTask: ((GanttTask, Date, Date) -> Void)? = nil  // (task, newStart, newEnd)

    @EnvironmentObject private var theme: ThemeStore

    private let rowHeight: CGFloat = 40
    private let labelWidth: CGFloat = 140
    private let headerHeight: CGFloat = 32

    /// 可用的圖表區域寬度（由 GeometryReader 動態計算）
    @State private var availableChartWidth: CGFloat = 0

    private var totalDays: Int {
        let cal = Calendar.current
        switch timeScale {
        case .day:   return 24  // 小時
        case .week:  return 7
        case .month:
            return cal.dateComponents([.day], from: dateRange.lowerBound, to: dateRange.upperBound).day ?? 30
        }
    }

    /// 每個單位的寬度 — 週模式自動平均分配螢幕寬度
    private var dayWidth: CGFloat {
        let available = availableChartWidth
        switch timeScale {
        case .week:
            return available > 0 ? available / 7 : 100
        case .day:
            return available > 0 ? max(available / 24, 50) : 50
        case .month:
            let days = CGFloat(totalDays)
            return available > 0 ? max(available / days, 36) : 36
        }
    }

    /// 是否需要橫向捲動（內容比可用空間寬時才捲動）
    private var needsHorizontalScroll: Bool {
        chartWidth > availableChartWidth && availableChartWidth > 0
    }

    private var chartWidth: CGFloat {
        dayWidth * CGFloat(totalDays)
    }

    var body: some View {
        if items.isEmpty && milestones.isEmpty {
            ContentUnavailableView(
                "沒有資料",
                systemImage: "chart.bar.xaxis",
                description: Text("點擊右下角「＋」新增任務")
            )
        } else {
            GeometryReader { geo in
                let chartAreaWidth = geo.size.width - labelWidth - 1 // 1 for divider
                VStack(spacing: 0) {
                    // 頂部：左側 picker + 右側整排日期
                    HStack(spacing: 0) {
                        Picker("", selection: $timeScale) {
                            ForEach(GanttTimeScale.allCases, id: \.self) { scale in
                                Text(scale.rawValue).tag(scale)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 8)
                        .frame(width: labelWidth, height: headerHeight)

                        Divider()

                        // 右側日期
                        if needsHorizontalScroll {
                            ScrollView(.horizontal, showsIndicators: false) {
                                dateHeader
                            }
                            .frame(height: headerHeight)
                        } else {
                            dateHeader
                                .frame(height: headerHeight)
                        }
                    }
                    .frame(height: headerHeight)
                    .background(Color(.systemBackground))

                    Divider()

                    // 下方：每一列是「任務名 + 該任務的橫條」
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(items) { item in
                                taskRow(item)
                            }
                        }
                    }
                }
                .onAppear { availableChartWidth = chartAreaWidth }
                .onChange(of: geo.size.width) { _, newWidth in
                    availableChartWidth = newWidth - labelWidth - 1
                }
            }
        }
    }

    // MARK: - Task Row (任務名 + 該任務的橫條在同一列)

    private func taskRow(_ item: GanttItem) -> some View {
        HStack(spacing: 0) {
            // 左側任務名
            taskLabel(item)

            Divider()

            // 右側甘特條區域
            let chartContent = ZStack(alignment: .topLeading) {
                rowBackground
                todayLineInRow
                ForEach(milestones) { ms in
                    milestoneLineInRow(ms)
                }
                ganttBar(item)
            }
            .frame(width: chartWidth, height: rowHeight)

            if needsHorizontalScroll {
                ScrollView(.horizontal, showsIndicators: false) {
                    chartContent
                }
            } else {
                chartContent
            }
        }
        .frame(height: rowHeight)
        .contextMenu {
            if let task = item.taskRef {
                Button {
                    onEditTask?(task)
                } label: {
                    Label("編輯", systemImage: "pencil")
                }

                // 只有頂層任務或父任務可以新增子任務
                if task.parentId == nil {
                    Button {
                        onAddSubtask?(task.id)
                    } label: {
                        Label("新增子任務", systemImage: "plus.circle")
                    }
                }

                Button {
                    onToggleDone?(task)
                } label: {
                    Label(task.isDone ? "標為未完成" : "標為完成", systemImage: task.isDone ? "circle" : "checkmark.circle")
                }

                Button(role: .destructive) {
                    onDeleteTask?(task)
                } label: {
                    Label("刪除", systemImage: "trash")
                }
            }
        }
    }

    private func taskLabel(_ item: GanttItem) -> some View {
        let indent = CGFloat(item.indentLevel) * 16
        let isParent = item.source == .parentTask

        return HStack(spacing: 6) {
            if isParent {
                // 父任務用摺疊圖示
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
            } else {
                Circle()
                    .fill(Color(hex: item.colorHex))
                    .frame(width: 8, height: 8)
            }

            Text(item.title)
                .font(isParent ? .caption.weight(.semibold) : .caption)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(item.isDone ? .secondary : .primary)
                .strikethrough(item.isDone)

            Spacer(minLength: 0)
        }
        .padding(.leading, 10 + indent)
        .padding(.trailing, 6)
        .frame(width: labelWidth, height: rowHeight, alignment: .leading)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider().opacity(0.3)
        }
    }

    // MARK: - Row Background (單列的週末底色 + 縱向格線)

    private var rowBackground: some View {
        ZStack(alignment: .topLeading) {
            // 週末底色
            if timeScale != .day {
                HStack(spacing: 0) {
                    ForEach(0..<totalDays, id: \.self) { i in
                        weekendTint(index: i)
                            .frame(width: dayWidth, height: rowHeight)
                    }
                }
            }

            // 縱向格線
            Canvas { context, size in
                for i in 0...totalDays {
                    let x = CGFloat(i) * dayWidth
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: .color(.secondary.opacity(0.08)), lineWidth: 0.5)
                }
            }
            .frame(width: chartWidth, height: rowHeight)

            // 底部分隔線
            VStack {
                Spacer()
                Divider().opacity(0.3)
            }
            .frame(width: chartWidth, height: rowHeight)
        }
    }

    // MARK: - Today / Milestone lines (single row version)

    private var todayLineInRow: some View {
        let x = xPosition(for: Date())
        return Group {
            if x >= 0 && x <= chartWidth {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 1.5, height: rowHeight)
                    .offset(x: x)
            }
        }
    }

    private func milestoneLineInRow(_ ms: GanttMilestone) -> some View {
        let x = xPosition(for: ms.date)
        return Group {
            if x >= 0 && x <= chartWidth {
                Rectangle()
                    .fill(Color(hex: ms.colorHex).opacity(0.5))
                    .frame(width: 1, height: rowHeight)
                    .offset(x: x)
            }
        }
    }

    // MARK: - Date Header（單排：日期 + 星期，週末有底色）

    private var dateHeader: some View {
        HStack(spacing: 0) {
            ForEach(0..<totalDays, id: \.self) { i in
                dayCell(index: i)
            }
        }
        .frame(width: chartWidth, height: headerHeight)
        .background(Color(.systemBackground).opacity(0.95))
    }

    private func dayCell(index: Int) -> some View {
        let cal = Calendar.current
        let isToday: Bool
        let topText: String
        let bottomText: String
        let weekdayKind: WeekdayKind

        if timeScale == .day {
            topText = "\(index):00"
            bottomText = ""
            isToday = false
            weekdayKind = .weekday
        } else {
            let date = cal.date(byAdding: .day, value: index, to: dateRange.lowerBound)!
            let day = cal.component(.day, from: date)
            let weekday = cal.component(.weekday, from: date)
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "zh_TW")
            fmt.dateFormat = "E"
            topText = "\(day)"
            bottomText = fmt.string(from: date)
            isToday = cal.isDateInToday(date)
            switch weekday {
            case 1: weekdayKind = .sunday
            case 7: weekdayKind = .saturday
            default: weekdayKind = .weekday
            }
        }

        let fgColor: Color
        if isToday {
            fgColor = .red
        } else {
            switch weekdayKind {
            case .sunday:   fgColor = Color.red.opacity(0.85)
            case .saturday: fgColor = Color.blue.opacity(0.85)
            case .weekday:  fgColor = .secondary
            }
        }

        let bgColor: Color
        if isToday {
            bgColor = Color.red.opacity(0.10)
        } else {
            switch weekdayKind {
            case .sunday:   bgColor = Color.red.opacity(0.05)
            case .saturday: bgColor = Color.blue.opacity(0.05)
            case .weekday:  bgColor = Color.clear
            }
        }

        return VStack(spacing: 0) {
            Text(topText)
                .font(.system(size: 11, weight: isToday ? .bold : .semibold))
            if !bottomText.isEmpty {
                Text(bottomText)
                    .font(.system(size: 9))
            }
        }
        .foregroundStyle(fgColor)
        .frame(width: dayWidth, height: headerHeight)
        .background(bgColor)
    }

    private enum WeekdayKind {
        case sunday, saturday, weekday
    }

    @ViewBuilder
    private func weekendTint(index: Int) -> some View {
        let cal = Calendar.current
        if let date = cal.date(byAdding: .day, value: index, to: dateRange.lowerBound) {
            let weekday = cal.component(.weekday, from: date)
            if weekday == 1 {
                Color.red.opacity(0.04)
            } else if weekday == 7 {
                Color.blue.opacity(0.04)
            } else {
                Color.clear
            }
        } else {
            Color.clear
        }
    }

    // MARK: - Gantt Bar

    private func ganttBar(_ item: GanttItem) -> some View {
        let isParent = item.source == .parentTask
        let (offset, width) = barGeometry(start: item.start, end: item.end)
        let canDrag = item.taskRef != nil && !isParent

        return ZStack(alignment: .leading) {
            Color.clear

            if isParent {
                // 父任務：細灰色摘要條
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.35))
                        .frame(width: max(width, 6), height: 8)
                    HStack {
                        parentEndcap
                        Spacer(minLength: 0)
                        parentEndcap
                    }
                    .frame(width: max(width, 6))
                }
                .offset(x: offset, y: 2)
            } else {
                // 緩衝條
                if let bufferEnd = item.bufferEnd {
                    let (bOffset, bWidth) = barGeometry(start: item.end, end: bufferEnd)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: item.colorHex).opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(Color(hex: item.colorHex).opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                        )
                        .frame(width: max(bWidth, 2), height: 22)
                        .offset(x: bOffset)
                }

                // 主條 + 拖拉端點
                HStack(spacing: 0) {
                    // 左端拖拉把手
                    if canDrag {
                        dragHandle(item: item, edge: .leading)
                    }

                    // 中間色塊
                    RoundedRectangle(cornerRadius: canDrag ? 0 : 4)
                        .fill(Color(hex: item.colorHex).opacity(item.isDone ? 0.35 : 0.85))
                        .frame(height: 22)

                    // 右端拖拉把手
                    if canDrag {
                        dragHandle(item: item, edge: .trailing)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .frame(width: max(width, 20), height: 22)
                .offset(x: offset)
            }
        }
        .frame(width: chartWidth, height: rowHeight)
    }

    /// 拖拉端點把手
    private func dragHandle(item: GanttItem, edge: HorizontalEdge) -> some View {
        let isEnd = edge == .trailing

        return Rectangle()
            .fill(Color(hex: item.colorHex).opacity(0.95))
            .frame(width: 10, height: 22)
            .overlay {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 7))
                    .foregroundStyle(.white.opacity(0.7))
                    .rotationEffect(.degrees(90))
            }
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onEnded { value in
                        guard let task = item.taskRef else { return }
                        let totalSeconds = dateRange.upperBound.timeIntervalSince(dateRange.lowerBound)
                        let dragSeconds = (Double(value.translation.width) / Double(chartWidth)) * totalSeconds

                        var newStart = task.start
                        var newEnd = task.end

                        if isEnd {
                            newEnd = newEnd.addingTimeInterval(dragSeconds)
                            newEnd = max(newEnd, newStart.addingTimeInterval(3600)) // 最少 1 小時
                        } else {
                            newStart = newStart.addingTimeInterval(dragSeconds)
                            newStart = min(newStart, newEnd.addingTimeInterval(-3600))
                        }

                        onResizeTask?(task, newStart, newEnd)
                    }
            )
    }

    /// 父任務摘要條的端點小三角
    private var parentEndcap: some View {
        Image(systemName: "arrowtriangle.down.fill")
            .font(.system(size: 6))
            .foregroundStyle(.secondary.opacity(0.5))
    }

    // MARK: - Geometry Helpers

    private func xPosition(for date: Date) -> CGFloat {
        let total = dateRange.upperBound.timeIntervalSince(dateRange.lowerBound)
        guard total > 0 else { return 0 }
        let offset = date.timeIntervalSince(dateRange.lowerBound)
        return CGFloat(offset / total) * chartWidth
    }

    private func barGeometry(start: Date, end: Date) -> (offset: CGFloat, width: CGFloat) {
        let total = dateRange.upperBound.timeIntervalSince(dateRange.lowerBound)
        guard total > 0 else { return (0, 0) }

        let s = max(start.timeIntervalSince(dateRange.lowerBound), 0)
        let e = min(end.timeIntervalSince(dateRange.lowerBound), total)

        return (CGFloat(s / total) * chartWidth, CGFloat((e - s) / total) * chartWidth)
    }

    // MARK: - Month Helpers

    private struct MonthSpan {
        let label: String
        let days: Int
    }

    private func visibleMonths() -> [MonthSpan] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "zh_TW")
        fmt.dateFormat = "yyyy年M月"

        var months: [MonthSpan] = []
        var current = dateRange.lowerBound
        let end = dateRange.upperBound

        while current < end {
            let label = fmt.string(from: current)
            let monthEnd = cal.date(byAdding: .month, value: 1, to: cal.date(from: cal.dateComponents([.year, .month], from: current))!)!
            let segmentEnd = min(monthEnd, end)
            let days = cal.dateComponents([.day], from: current, to: segmentEnd).day ?? 1
            months.append(MonthSpan(label: label, days: max(days, 1)))
            current = segmentEnd
        }

        return months
    }
}
