import SwiftUI

/// 甘特圖核心視圖 — 橫向捲動的時間軸 + 橫條 + 里程碑 + 緩衝
struct GanttChartView: View {
    let items: [GanttItem]
    let milestones: [GanttMilestone]
    let timeScale: GanttTimeScale
    let dateRange: ClosedRange<Date>

    @EnvironmentObject private var theme: ThemeStore

    private let rowHeight: CGFloat = 44
    private let labelWidth: CGFloat = 100

    private var unitWidth: CGFloat {
        switch timeScale {
        case .day:   return 50
        case .week:  return 110
        case .month: return 38
        }
    }

    private var totalWidth: CGFloat {
        let cal = Calendar.current
        switch timeScale {
        case .day:
            return unitWidth * 24
        case .week:
            return unitWidth * 7
        case .month:
            let days = cal.dateComponents([.day], from: dateRange.lowerBound, to: dateRange.upperBound).day ?? 30
            return unitWidth * CGFloat(days)
        }
    }

    var body: some View {
        if items.isEmpty && milestones.isEmpty {
            ContentUnavailableView(
                "沒有資料",
                systemImage: "chart.bar.xaxis",
                description: Text("此期間沒有行事曆事件或有時間範圍的待辦事項")
            )
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    timeAxisHeader
                    Divider()

                    // 里程碑列（如果有的話）
                    if !milestones.isEmpty {
                        milestoneRow
                        Divider().opacity(0.3)
                    }

                    // 甘特條列表
                    ForEach(items) { item in
                        ganttRow(item)
                        Divider().opacity(0.3)
                    }
                }
            }
        }
    }

    // MARK: - Time Axis Header

    private var timeAxisHeader: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: labelWidth, height: 32)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(timeLabels, id: \.offset) { label in
                        Text(label.text)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: unitWidth, alignment: .leading)
                    }
                }
                .frame(width: totalWidth, alignment: .leading)
            }
        }
        .background(Color(.systemBackground).opacity(0.9))
    }

    // MARK: - Milestone Row

    private var milestoneRow: some View {
        HStack(spacing: 0) {
            Text("里程碑")
                .font(.caption.weight(.semibold))
                .frame(width: labelWidth, alignment: .leading)
                .padding(.leading, 8)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .leading) {
                    gridLines
                        .frame(width: totalWidth, height: rowHeight)

                    ForEach(milestones) { ms in
                        let x = xPosition(for: ms.date)
                        VStack(spacing: 2) {
                            // 菱形標記
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: ms.colorHex))
                            Text(ms.title)
                                .font(.system(size: 8))
                                .foregroundStyle(Color(hex: ms.colorHex))
                                .lineLimit(1)
                        }
                        .offset(x: x - 10)
                    }
                }
                .frame(width: totalWidth, height: rowHeight)
            }
        }
        .frame(height: rowHeight)
    }

    // MARK: - Gantt Row

    private func ganttRow(_ item: GanttItem) -> some View {
        HStack(spacing: 0) {
            Text(item.title)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: labelWidth, alignment: .leading)
                .padding(.leading, 8)
                .foregroundStyle(item.isDone ? .secondary : .primary)
                .strikethrough(item.isDone)

            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .leading) {
                    gridLines
                        .frame(width: totalWidth, height: rowHeight)

                    // 緩衝條（在主條後面，先畫）
                    if let bufferEnd = item.bufferEnd {
                        let (bufferOffset, bufferWidth) = barGeometry(start: item.end, end: bufferEnd)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: item.colorHex).opacity(0.25))
                            .frame(width: max(bufferWidth, 2), height: 24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color(hex: item.colorHex).opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            )
                            .offset(x: bufferOffset)
                    }

                    // 主甘特條
                    let (offset, width) = barGeometry(start: item.start, end: item.end)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: item.colorHex).opacity(item.isDone ? 0.35 : 0.85))
                        .frame(width: max(width, 4), height: 24)
                        .overlay(
                            Text(item.title)
                                .font(.system(size: 10))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .padding(.horizontal, 4),
                            alignment: .leading
                        )
                        .offset(x: offset)

                    // 里程碑標記（疊在甘特條上）
                    ForEach(milestones) { ms in
                        let msX = xPosition(for: ms.date)
                        if msX >= offset && msX <= offset + width + 20 {
                            Rectangle()
                                .fill(Color(hex: ms.colorHex))
                                .frame(width: 1.5, height: rowHeight)
                                .offset(x: msX)
                        }
                    }
                }
                .frame(width: totalWidth, height: rowHeight)
            }
        }
        .frame(height: rowHeight)
    }

    // MARK: - Grid Lines

    private var gridLines: some View {
        Canvas { context, size in
            let count: Int
            switch timeScale {
            case .day:   count = 24
            case .week:  count = 7
            case .month: count = Int(size.width / unitWidth)
            }

            for i in 0...count {
                let x = CGFloat(i) * unitWidth
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.secondary.opacity(0.15)), lineWidth: 0.5)
            }
        }
    }

    // MARK: - Geometry Helpers

    private func xPosition(for date: Date) -> CGFloat {
        let totalSeconds = dateRange.upperBound.timeIntervalSince(dateRange.lowerBound)
        guard totalSeconds > 0 else { return 0 }
        let seconds = date.timeIntervalSince(dateRange.lowerBound)
        return CGFloat(seconds / totalSeconds) * totalWidth
    }

    private func barGeometry(start: Date, end: Date) -> (offset: CGFloat, width: CGFloat) {
        let totalSeconds = dateRange.upperBound.timeIntervalSince(dateRange.lowerBound)
        guard totalSeconds > 0 else { return (0, 0) }

        let startSeconds = max(start.timeIntervalSince(dateRange.lowerBound), 0)
        let endSeconds = min(end.timeIntervalSince(dateRange.lowerBound), totalSeconds)

        let offset = CGFloat(startSeconds / totalSeconds) * totalWidth
        let width = CGFloat((endSeconds - startSeconds) / totalSeconds) * totalWidth

        return (offset, width)
    }

    // MARK: - Time Labels

    private struct TimeLabel {
        let offset: Int
        let text: String
    }

    private var timeLabels: [TimeLabel] {
        let cal = Calendar.current
        var labels: [TimeLabel] = []

        switch timeScale {
        case .day:
            for h in 0..<24 {
                labels.append(TimeLabel(offset: h, text: "\(h):00"))
            }
        case .week:
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "zh_TW")
            fmt.dateFormat = "E\nM/d"
            for d in 0..<7 {
                let date = cal.date(byAdding: .day, value: d, to: dateRange.lowerBound)!
                labels.append(TimeLabel(offset: d, text: fmt.string(from: date)))
            }
        case .month:
            let days = cal.dateComponents([.day], from: dateRange.lowerBound, to: dateRange.upperBound).day ?? 30
            for d in 0..<days {
                let date = cal.date(byAdding: .day, value: d, to: dateRange.lowerBound)!
                let dayNum = cal.component(.day, from: date)
                labels.append(TimeLabel(offset: d, text: "\(dayNum)"))
            }
        }

        return labels
    }
}
