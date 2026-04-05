import Foundation
import SwiftUI
import Combine

// MARK: - TomorrowRingStore

@MainActor
final class TomorrowRingStore: ObservableObject {

    // MARK: - Storage Keys

    private enum Keys {
        static let plan = "tomorrow_ring_plan_v2"
        static let classSchedule = "class_schedule_v2"
        static let weeklyTemplate = "weekly_template_v2"
        static let showSegmentIcons = "ring_showSegmentIcons"
        static let lastLoadedDate = "ring_last_loaded_date_v2"
        static let deductedSegments = "ring_deducted_segments_v2"
    }

    // MARK: - Published State

    @Published var plan: RingPlanV2 {
        didSet { savePlan() }
    }

    @Published var classSchedule: ClassScheduleV2 {
        didSet { saveClassSchedule() }
    }

    @Published var weeklyTemplate: WeeklyTemplateV2 {
        didSet { saveWeeklyTemplate() }
    }

    @Published var showSegmentIcons: Bool {
        didSet { StorageManager.save(showSegmentIcons, forKey: Keys.showSegmentIcons) }
    }

    // MARK: - Undo

    let planUndoManager = RingUndoManager()
    let actualUndoManager = RingUndoManager()

    // MARK: - Init

    init() {
        Self.migrateFromV1IfNeeded()

        self.plan = StorageManager.load(RingPlanV2.self, forKey: Keys.plan)
            ?? RingPlanV2(date: Date())
        self.classSchedule = StorageManager.load(ClassScheduleV2.self, forKey: Keys.classSchedule)
            ?? ClassScheduleV2()
        self.weeklyTemplate = StorageManager.load(WeeklyTemplateV2.self, forKey: Keys.weeklyTemplate)
            ?? WeeklyTemplateV2()
        self.showSegmentIcons = StorageManager.load(Bool.self, forKey: Keys.showSegmentIcons)
            ?? true
    }

    // MARK: - Plan CRUD (Inner Ring)

    @discardableResult
    func addPlanItem(_ item: RingItemV2) -> Result<Void, RingCollisionEngine.CollisionError> {
        let result = RingCollisionEngine.validate(item: item, among: plan.planItems)
        if case .success = result {
            planUndoManager.push(plan.planItems)
            plan.planItems.append(item)
            plan.planItems.sort { $0.startMinute < $1.startMinute }
        }
        return result
    }

    @discardableResult
    func updatePlanItem(_ item: RingItemV2) -> Result<Void, RingCollisionEngine.CollisionError> {
        let result = RingCollisionEngine.validate(item: item, among: plan.planItems)
        if case .success = result {
            planUndoManager.push(plan.planItems)
            if let idx = plan.planItems.firstIndex(where: { $0.id == item.id }) {
                plan.planItems[idx] = item
                plan.planItems.sort { $0.startMinute < $1.startMinute }
            }
        }
        return result
    }

    func removePlanItem(id: UUID) {
        planUndoManager.push(plan.planItems)
        plan.planItems.removeAll { $0.id == id }
    }

    @discardableResult
    func movePlanItem(id: UUID, toStart newStart: Int) -> Result<Void, RingCollisionEngine.CollisionError> {
        guard var item = plan.planItems.first(where: { $0.id == id }) else {
            return .failure(.noValidPosition)
        }
        let dur = item.duration
        item.startMinute = newStart
        item.endMinute = (newStart + dur) % RingTimeHelpers.totalMinutes
        return updatePlanItem(item)
    }

    // MARK: - Actual CRUD (Outer Ring)

    func initializeActualFromPlan() {
        actualUndoManager.push(plan.actualItems)
        plan.initializeActual()
    }

    func adjustActualItem(id: UUID, start: Int, end: Int) {
        if let idx = plan.actualItems.firstIndex(where: { $0.id == id }) {
            actualUndoManager.push(plan.actualItems)
            plan.actualItems[idx].startMinute = start
            plan.actualItems[idx].endMinute = end
        }
    }

    func addActualItem(_ item: RingItemV2) {
        actualUndoManager.push(plan.actualItems)
        plan.actualItems.append(item)
        plan.actualItems.sort { $0.startMinute < $1.startMinute }
    }

    func removeActualItem(id: UUID) {
        actualUndoManager.push(plan.actualItems)
        plan.actualItems.removeAll { $0.id == id }
    }

    // MARK: - Undo / Redo

    func undoPlan() {
        if let prev = planUndoManager.undo(current: plan.planItems) {
            plan.planItems = prev
        }
    }

    func redoPlan() {
        if let next = planUndoManager.redo(current: plan.planItems) {
            plan.planItems = next
        }
    }

    func undoActual() {
        if let prev = actualUndoManager.undo(current: plan.actualItems) {
            plan.actualItems = prev
        }
    }

    func redoActual() {
        if let next = actualUndoManager.redo(current: plan.actualItems) {
            plan.actualItems = next
        }
    }

    // MARK: - Class Schedule → Plan

    /// Apply today's class schedule to planItems if not already applied today.
    func applyClassScheduleIfNeeded() {
        let today = dateKey(for: Date())
        let lastLoaded = StorageManager.load(String.self, forKey: Keys.lastLoadedDate)

        guard lastLoaded != today else { return }

        let day = Weekday.today
        let courses = classSchedule.toRingItems(for: day)

        // Only add courses that don't already exist (by comparing start/end/title)
        for course in courses {
            let alreadyExists = plan.planItems.contains {
                $0.startMinute == course.startMinute
                && $0.endMinute == course.endMinute
                && $0.title == course.title
            }
            if !alreadyExists {
                // Skip collision check for class schedule — they take priority
                plan.planItems.append(course)
            }
        }
        plan.planItems.sort { $0.startMinute < $1.startMinute }

        StorageManager.save(today, forKey: Keys.lastLoadedDate)
    }

    // MARK: - Auto-Deduct HP/FP

    /// Deduct HP/FP for completed actual segments. Call from LifeGame integration.
    func deductCompletedSegments(game: LifeGame) {
        let now = RingTimeHelpers.minute(from: Date())
        let today = dateKey(for: Date())
        var deducted = StorageManager.load([String].self, forKey: Keys.deductedSegments) ?? []

        for item in plan.actualItems {
            let segKey = "\(today)_\(item.id.uuidString)"
            guard !deducted.contains(segKey) else { continue }

            // Check if segment has ended
            let ended: Bool
            if item.startMinute < item.endMinute {
                ended = now >= item.endMinute
            } else {
                // Cross-midnight: ended if past midnight and past endMinute
                ended = now >= item.endMinute && now < item.startMinute
            }

            if ended {
                game.hp.current = max(0, game.hp.current - item.hpCost)
                game.fp.current = max(0, game.fp.current - item.fpCost)
                deducted.append(segKey)
            }
        }

        StorageManager.save(deducted, forKey: Keys.deductedSegments)
    }

    // MARK: - Persistence (private)

    private func savePlan() {
        StorageManager.save(plan, forKey: Keys.plan)
    }

    private func saveClassSchedule() {
        StorageManager.save(classSchedule, forKey: Keys.classSchedule)
    }

    private func saveWeeklyTemplate() {
        StorageManager.save(weeklyTemplate, forKey: Keys.weeklyTemplate)
    }

    private func dateKey(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    // MARK: - V1 Migration

    static func migrateFromV1IfNeeded() {
        // Skip if V2 data already exists
        if StorageManager.load(RingPlanV2.self, forKey: Keys.plan) != nil {
            return
        }

        // Migrate plan
        if let v1Plan = StorageManager.load(TomorrowRingPlan.self, forKey: "tomorrow_ring_plan") {
            let v2Plan = RingPlanV2(from: v1Plan)
            StorageManager.save(v2Plan, forKey: Keys.plan)
        }

        // Migrate weekly schedule → weekly template
        if let v1Schedule = StorageManager.load(WeeklySchedule.self, forKey: "weekly_schedule_v1") {
            let v2Template = WeeklyTemplateV2(from: v1Schedule)
            StorageManager.save(v2Template, forKey: Keys.weeklyTemplate)
        }

        // V1 data is NOT deleted — both coexist
    }
}
