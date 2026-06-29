import Foundation

/// 註冊各「集合型」store 的跨裝置同步合併策略（union-by-id）。
///
/// 在 App 啟動、執行任何去重/載入「之前」呼叫一次（見 MyApp.init）。
/// 未在此註冊的 key 一律維持 last-write-wins（安全預設）。
///
/// 註：此處的 key 字串需與各 store 內使用的 storageKey 一致；若日後 store 改 key（如 v1→v2），
/// 這裡也要同步更新——萬一漏改，該 key 只會退回 LWW（原本行為），不會出錯。
enum SyncMergeRegistration {
    static func registerAll() {
        let r = KeyValueMergeRegistry.self

        // MARK: - 陣列型（union by id）
        r.register("wish_items_v1",          merge: r.arrayMerge(WishItem.self))
        r.register("ledger_entries_v1",      merge: r.arrayMerge(LedgerEntry.self))
        r.register("habits_v1",              merge: r.arrayMerge(Habit.self))
        r.register("mood_history_points_v1", merge: r.arrayMerge(MoodPoint.self))
        r.register("calendar_events_v1",     merge: r.arrayMerge(CalendarEvent.self))
        r.register("todo_quadrant_v1",       merge: r.arrayMerge(TodoItem.self))
        r.register("gantt_tasks_v1",         merge: r.arrayMerge(GanttTask.self))
        r.register("gantt_milestones_v1",    merge: r.arrayMerge(GanttMilestone.self))
        r.register("diary_entries_v1",       merge: r.arrayMerge(DiaryEntry.self))
        r.register("equipments_v1",          merge: r.arrayMerge(EquipItem.self))
        r.register("custom_tabs_v1",         merge: r.arrayMerge(CustomTab.self))
        r.register("question_modules_v1",    merge: r.arrayMerge(DailyLogModule.self))
        r.register("quick_pages_v1",         merge: r.arrayMerge(QuickPage.self))
        r.register("practice_diaries_v1",    merge: r.arrayMerge(PracticeDiary.self))
        r.register("aquarium_v1",            merge: r.arrayMerge(AquariumTask.self))

        // MARK: - 字典型（[String: V]，union of keys）
        r.register("history_records_v1",       merge: r.dictMerge(DayRecord.self))
        r.register("daily_records_v1",         merge: r.dictMerge(DailyRecord.self))
        r.register("monthly_scores_by_day_v1", merge: r.dictMerge(Int.self))
        r.register("weekReview.data",          merge: r.dictMerge(WeekReview.self))
        r.register("Key3.plansData",           merge: r.dictMerge(Key3Plan.self))
    }
}
