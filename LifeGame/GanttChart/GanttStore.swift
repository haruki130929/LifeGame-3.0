import Foundation
import SwiftUI
import Combine

@MainActor
final class GanttStore: ObservableObject {

    @Published var timeScale: GanttTimeScale = .week
    @Published var anchorDate: Date = Date()
    @Published var showBuffer: Bool = true
    @Published var bufferPercent: Double = 15  // 10-20%

    // MARK: - Milestones

    @Published var milestones: [GanttMilestone] = [] {
        didSet { saveMilestones() }
    }

    private let milestonesKey = "gantt_milestones_v1"
    private let cal = Calendar.current

    init() {
        milestones = StorageManager.load([GanttMilestone].self, forKey: milestonesKey) ?? []
    }

    func addMilestone(title: String, date: Date, colorHex: String = "FF6B6B") {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        milestones.append(GanttMilestone(title: t, date: date, colorHex: colorHex))
    }

    func deleteMilestone(_ milestone: GanttMilestone) {
        milestones.removeAll { $0.id == milestone.id }
    }

    private func saveMilestones() {
        StorageManager.save(milestones, forKey: milestonesKey)
    }

    /// 取得可見範圍內的里程碑
    func visibleMilestones() -> [GanttMilestone] {
        let range = visibleDateRange
        return milestones.filter { $0.date >= range.lowerBound && $0.date <= range.upperBound }
    }

    // MARK: - Visible Date Range

    var visibleDateRange: ClosedRange<Date> {
        let start: Date
        let end: Date

        switch timeScale {
        case .day:
            start = cal.startOfDay(for: anchorDate)
            end = cal.date(byAdding: .day, value: 1, to: start)!
        case .week:
            let weekday = cal.component(.weekday, from: anchorDate)
            let daysToMonday = (weekday + 5) % 7
            start = cal.startOfDay(for: cal.date(byAdding: .day, value: -daysToMonday, to: anchorDate)!)
            end = cal.date(byAdding: .day, value: 7, to: start)!
        case .month:
            let comps = cal.dateComponents([.year, .month], from: anchorDate)
            start = cal.date(from: comps)!
            end = cal.date(byAdding: .month, value: 1, to: start)!
        }

        return start...end
    }

    var dateRangeLabel: String {
        let range = visibleDateRange
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "zh_TW")

        switch timeScale {
        case .day:
            fmt.dateFormat = "M月d日 (E)"
            return fmt.string(from: range.lowerBound)
        case .week:
            fmt.dateFormat = "M/d"
            let startStr = fmt.string(from: range.lowerBound)
            let endDate = cal.date(byAdding: .day, value: -1, to: range.upperBound)!
            let endStr = fmt.string(from: endDate)
            return "\(startStr) – \(endStr)"
        case .month:
            fmt.dateFormat = "yyyy年M月"
            return fmt.string(from: range.lowerBound)
        }
    }

    // MARK: - Navigation

    func goForward() {
        switch timeScale {
        case .day:   anchorDate = cal.date(byAdding: .day, value: 1, to: anchorDate)!
        case .week:  anchorDate = cal.date(byAdding: .weekOfYear, value: 1, to: anchorDate)!
        case .month: anchorDate = cal.date(byAdding: .month, value: 1, to: anchorDate)!
        }
    }

    func goBackward() {
        switch timeScale {
        case .day:   anchorDate = cal.date(byAdding: .day, value: -1, to: anchorDate)!
        case .week:  anchorDate = cal.date(byAdding: .weekOfYear, value: -1, to: anchorDate)!
        case .month: anchorDate = cal.date(byAdding: .month, value: -1, to: anchorDate)!
        }
    }

    func jumpToToday() {
        anchorDate = Date()
    }

    // MARK: - Build Items

    func buildItems(from calendarStore: CalendarStore, todoStore: TodoQuadrantStore) -> [GanttItem] {
        let range = visibleDateRange
        let bufferRatio = showBuffer ? bufferPercent / 100.0 : 0
        var result: [GanttItem] = []

        // Calendar events
        for event in calendarStore.events {
            if event.end > range.lowerBound && event.start < range.upperBound {
                let bufferEnd: Date? = bufferRatio > 0
                    ? event.end.addingTimeInterval(event.end.timeIntervalSince(event.start) * bufferRatio)
                    : nil
                result.append(GanttItem(
                    id: event.id,
                    title: event.title,
                    start: event.start,
                    end: event.end,
                    colorHex: event.colorHex,
                    source: .calendar,
                    isDone: false,
                    bufferEnd: bufferEnd
                ))
            }
        }

        // Todo items (only those with both startDate and dueDate)
        for item in todoStore.items {
            guard let startDate = item.startDate, let dueDate = item.dueDate else { continue }
            let effectiveEnd = max(dueDate, cal.date(byAdding: .hour, value: 1, to: startDate)!)
            if effectiveEnd > range.lowerBound && startDate < range.upperBound {
                let bufferEnd: Date? = bufferRatio > 0
                    ? effectiveEnd.addingTimeInterval(effectiveEnd.timeIntervalSince(startDate) * bufferRatio)
                    : nil
                result.append(GanttItem(
                    id: item.id,
                    title: item.title,
                    start: startDate,
                    end: effectiveEnd,
                    colorHex: "5B8DEF",
                    source: .todo,
                    isDone: item.isDone,
                    bufferEnd: bufferEnd
                ))
            }
        }

        result.sort { $0.start < $1.start }
        return result
    }
}
