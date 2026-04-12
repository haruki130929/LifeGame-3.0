import Foundation
import SwiftUI
import Combine

@MainActor
final class GanttStore: ObservableObject {

    @Published var timeScale: GanttTimeScale = .week
    @Published var anchorDate: Date = Date()
    @Published var showBuffer: Bool = false
    @Published var bufferPercent: Double = 15

    // MARK: - 使用者自建任務

    @Published var tasks: [GanttTask] = [] {
        didSet { if !isReloading { saveTasks() } }
    }

    // MARK: - Milestones

    @Published var milestones: [GanttMilestone] = [] {
        didSet { if !isReloading { saveMilestones() } }
    }

    private let tasksKey = "gantt_tasks_v1"
    private let milestonesKey = "gantt_milestones_v1"
    private let cal = Calendar.current
    private var isReloading = false
    private var syncHelper: StoreSyncHelper?

    init() {
        tasks = StorageManager.load([GanttTask].self, forKey: tasksKey) ?? []
        milestones = StorageManager.load([GanttMilestone].self, forKey: milestonesKey) ?? []
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }

        // 資料為空時建立範例資料
        if tasks.isEmpty {
            createSampleData()
        }
    }

    /// 建立範例資料，展示所有功能
    private func createSampleData() {
        // 從三天前開始，確保當前週能看到任務
        let today = cal.date(byAdding: .day, value: -3, to: cal.startOfDay(for: Date()))!

        // ── 父任務 A：App 設計（粉紅色系）──
        let parentA = GanttTask(
            title: "App 設計",
            start: today,
            end: cal.date(byAdding: .day, value: 10, to: today)!,
            colorHex: "E64980",
            order: 0
        )
        tasks.append(parentA)

        // 子任務 A-1：使用者訪談（序列，3天）
        tasks.append(GanttTask(
            title: "使用者訪談",
            start: today,
            end: cal.date(byAdding: .day, value: 3, to: today)!,
            colorHex: "E64980",
            order: 0,
            parentId: parentA.id,
            isSequential: false
        ))

        // 子任務 A-2：wireframe 設計（序列，4天，接在 A-1 後面）
        let a2Start = cal.date(byAdding: .day, value: 3, to: today)!
        tasks.append(GanttTask(
            title: "Wireframe 設計",
            start: a2Start,
            end: cal.date(byAdding: .day, value: 4, to: a2Start)!,
            colorHex: "E64980",
            order: 1,
            parentId: parentA.id,
            isSequential: true
        ))

        // 子任務 A-3：UI 設計（序列，3天，接在 A-2 後面）
        let a3Start = cal.date(byAdding: .day, value: 4, to: a2Start)!
        tasks.append(GanttTask(
            title: "UI 設計",
            start: a3Start,
            end: cal.date(byAdding: .day, value: 3, to: a3Start)!,
            colorHex: "E64980",
            order: 2,
            parentId: parentA.id,
            isSequential: true
        ))

        // ── 父任務 B：開發（黃綠色系）──
        let bStart = cal.date(byAdding: .day, value: 5, to: today)!
        let parentB = GanttTask(
            title: "開發",
            start: bStart,
            end: cal.date(byAdding: .day, value: 14, to: bStart)!,
            colorHex: "82C91E",
            order: 1
        )
        tasks.append(parentB)

        // 子任務 B-1：前端開發（6天）
        tasks.append(GanttTask(
            title: "前端開發",
            start: bStart,
            end: cal.date(byAdding: .day, value: 6, to: bStart)!,
            colorHex: "82C91E",
            order: 0,
            parentId: parentB.id,
            isSequential: false
        ))

        // 子任務 B-2：後端 API（序列，5天）
        let b2Start = cal.date(byAdding: .day, value: 6, to: bStart)!
        tasks.append(GanttTask(
            title: "後端 API",
            start: b2Start,
            end: cal.date(byAdding: .day, value: 5, to: b2Start)!,
            colorHex: "82C91E",
            order: 1,
            parentId: parentB.id,
            isSequential: true
        ))

        // 子任務 B-3：整合測試（序列，3天）
        let b3Start = cal.date(byAdding: .day, value: 5, to: b2Start)!
        tasks.append(GanttTask(
            title: "整合測試",
            start: b3Start,
            end: cal.date(byAdding: .day, value: 3, to: b3Start)!,
            colorHex: "82C91E",
            order: 2,
            parentId: parentB.id,
            isSequential: true
        ))

        // ── 獨立任務 C：撰寫文件（青色，無子任務）──
        let cStart = cal.date(byAdding: .day, value: 15, to: today)!
        tasks.append(GanttTask(
            title: "撰寫文件",
            start: cStart,
            end: cal.date(byAdding: .day, value: 4, to: cStart)!,
            colorHex: "15AABF",
            order: 2
        ))

        // ── 里程碑 ──
        milestones.append(GanttMilestone(
            title: "設計完成",
            date: a3Start.addingTimeInterval(3 * 86400),
            colorHex: "FF6B6B"
        ))

        milestones.append(GanttMilestone(
            title: "Beta 上線",
            date: b3Start.addingTimeInterval(3 * 86400),
            colorHex: "339AF0"
        ))

        // 更新父任務範圍
        updateParentRange(parentId: parentA.id)
        updateParentRange(parentId: parentB.id)

        // 開啟緩衝顯示
        showBuffer = true
        bufferPercent = 15
    }

    private func reloadFromStorage() {
        isReloading = true
        defer { isReloading = false }
        tasks = StorageManager.load([GanttTask].self, forKey: tasksKey) ?? []
        milestones = StorageManager.load([GanttMilestone].self, forKey: milestonesKey) ?? []
    }

    // MARK: - Task CRUD

    func addTask(title: String, start: Date, end: Date, colorHex: String = "339AF0") {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let order = (tasks.map(\.order).max() ?? -1) + 1
        tasks.append(GanttTask(title: t, start: start, end: max(end, start), colorHex: colorHex, order: order))
    }

    func updateTask(_ task: GanttTask) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx] = task
    }

    func deleteTask(_ task: GanttTask) {
        // 刪除任務時也刪除其子任務
        let childIds = subtasks(of: task.id).map(\.id)
        tasks.removeAll { $0.id == task.id || childIds.contains($0.id) }
    }

    func toggleTaskDone(_ task: GanttTask) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx].isDone.toggle()
    }

    func moveTask(from source: IndexSet, to destination: Int) {
        tasks.move(fromOffsets: source, toOffset: destination)
        for i in tasks.indices { tasks[i].order = i }
    }

    // MARK: - Subtask CRUD

    /// 取得某任務的子任務（按 order 排序）
    func subtasks(of parentId: UUID) -> [GanttTask] {
        tasks.filter { $0.parentId == parentId }.sorted { $0.order < $1.order }
    }

    /// 取得頂層任務（沒有 parentId 的）
    func topLevelTasks() -> [GanttTask] {
        tasks.filter { $0.parentId == nil }.sorted { $0.order < $1.order }
    }

    /// 新增子任務
    func addSubtask(title: String, parentId: UUID, duration: TimeInterval = 86400, isSequential: Bool = false, colorHex: String? = nil) {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }

        let parent = tasks.first(where: { $0.id == parentId })
        let siblings = subtasks(of: parentId)
        let order = (siblings.map(\.order).max() ?? -1) + 1

        // 如果是序列模式，開始時間 = 上一個子任務的結束時間
        let startDate: Date
        if isSequential, let lastSibling = siblings.last {
            startDate = lastSibling.end
        } else {
            startDate = parent?.start ?? Date()
        }

        let color = colorHex ?? parent?.colorHex ?? "339AF0"

        tasks.append(GanttTask(
            title: t,
            start: startDate,
            end: startDate.addingTimeInterval(duration),
            colorHex: color,
            order: order,
            parentId: parentId,
            isSequential: isSequential
        ))

        updateParentRange(parentId: parentId)
    }

    /// 自動對齊序列子任務：上一個結束 = 下一個開始
    func alignSequentialSubtasks(parentId: UUID) {
        let subs = subtasks(of: parentId)
        var previousEnd: Date?

        for sub in subs {
            guard let idx = tasks.firstIndex(where: { $0.id == sub.id }) else { continue }

            if sub.isSequential, let prevEnd = previousEnd {
                let duration = tasks[idx].end.timeIntervalSince(tasks[idx].start)
                tasks[idx].start = prevEnd
                tasks[idx].end = prevEnd.addingTimeInterval(duration)
            }

            previousEnd = tasks[idx].end
        }

        updateParentRange(parentId: parentId)
    }

    /// 更新子任務時間後，重新對齊後續序列子任務
    func updateSubtaskAndRealign(_ task: GanttTask) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx] = task
        if let parentId = task.parentId {
            alignSequentialSubtasks(parentId: parentId)
        }
    }

    /// 更新父任務的時間範圍（涵蓋所有子任務）
    private func updateParentRange(parentId: UUID) {
        let subs = subtasks(of: parentId)
        guard !subs.isEmpty,
              let idx = tasks.firstIndex(where: { $0.id == parentId }) else { return }

        let minStart = subs.map(\.start).min()!
        let maxEnd = subs.map(\.end).max()!
        tasks[idx].start = minStart
        tasks[idx].end = maxEnd
    }

    // MARK: - Milestone CRUD

    func addMilestone(title: String, date: Date, colorHex: String = "FF6B6B") {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        milestones.append(GanttMilestone(title: t, date: date, colorHex: colorHex))
    }

    func deleteMilestone(_ milestone: GanttMilestone) {
        milestones.removeAll { $0.id == milestone.id }
    }

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

        // 使用者自建任務（階層排列：父任務 → 子任務）
        for parent in topLevelTasks() {
            let children = subtasks(of: parent.id)
            let hasChildren = !children.isEmpty

            if parent.end > range.lowerBound && parent.start < range.upperBound {
                result.append(GanttItem(
                    id: parent.id, title: parent.title, start: parent.start, end: parent.end,
                    colorHex: parent.colorHex,
                    source: hasChildren ? .parentTask : .custom,
                    isDone: parent.isDone, indentLevel: 0, taskRef: parent
                ))
            }

            // 子任務
            for child in children {
                if child.end > range.lowerBound && child.start < range.upperBound {
                    let bufferEnd: Date? = bufferRatio > 0
                        ? child.end.addingTimeInterval(child.end.timeIntervalSince(child.start) * bufferRatio)
                        : nil
                    result.append(GanttItem(
                        id: child.id, title: child.title, start: child.start, end: child.end,
                        colorHex: child.colorHex, source: .custom, isDone: child.isDone,
                        bufferEnd: bufferEnd, indentLevel: 1, taskRef: child
                    ))
                }
            }
        }

        // Calendar events
        for event in calendarStore.events {
            if event.end > range.lowerBound && event.start < range.upperBound {
                result.append(GanttItem(
                    id: event.id, title: event.title, start: event.start, end: event.end,
                    colorHex: event.colorHex, source: .calendar, isDone: false
                ))
            }
        }

        // Todo items
        for item in todoStore.items {
            guard let startDate = item.startDate, let dueDate = item.dueDate else { continue }
            let effectiveEnd = max(dueDate, cal.date(byAdding: .hour, value: 1, to: startDate)!)
            if effectiveEnd > range.lowerBound && startDate < range.upperBound {
                result.append(GanttItem(
                    id: item.id, title: item.title, start: startDate, end: effectiveEnd,
                    colorHex: "5B8DEF", source: .todo, isDone: item.isDone
                ))
            }
        }

        return result
    }

    // MARK: - Persistence

    private func saveTasks() {
        StorageManager.save(tasks, forKey: tasksKey)
    }

    private func saveMilestones() {
        StorageManager.save(milestones, forKey: milestonesKey)
    }
}
