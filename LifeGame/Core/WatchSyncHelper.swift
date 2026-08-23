import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - 共享 Codable 型別（iOS ↔ watchOS 共用）

struct SyncStatCodable: Codable {
    var current: Int
    var max: Int
}

struct SyncStatsPayload: Codable {
    var hp: SyncStatCodable
    var fp: SyncStatCodable
    var mp: SyncStatCodable
}

/// 將 iOS 端資料同步到 App Groups 的 shared UserDefaults，供 watchOS 讀取
enum WatchSyncHelper {

    private static var defaults: UserDefaults { SharedConstants.sharedDefaults }

    /// 通知桌面 Widget 刷新（任一共享資料變動後呼叫）
    private static func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    // MARK: - Stats (HP / FP / MP)

    static func syncStats(hp: Stat, fp: Stat, mp: Stat) {
        let payload = SyncStatsPayload(
            hp: SyncStatCodable(current: hp.current, max: hp.max),
            fp: SyncStatCodable(current: fp.current, max: fp.max),
            mp: SyncStatCodable(current: mp.current, max: mp.max)
        )
        do {
            let data = try JSONEncoder().encode(payload)
            defaults.set(data, forKey: SharedConstants.Keys.stats)
            reloadWidgets()
            // 若使用者開了「今日狀態」即時動態，一併更新（內部會判斷是否開啟）
            LiveActivityController.update(hp: hp, fp: fp, mp: mp)
        } catch {
            debugLog("⚠️ WatchSync: Stats 編碼失敗 - \(error.localizedDescription)")
        }
    }

    // MARK: - Mood (今日心情紀錄)

    static func syncMoodEntries(_ entries: [MoodEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            defaults.set(data, forKey: SharedConstants.Keys.mood)
            reloadWidgets()
        } catch {
            debugLog("⚠️ WatchSync: Mood 編碼失敗 - \(error.localizedDescription)")
        }
    }

    // MARK: - 主動推一次完整快照

    /// 直接從儲存層讀出心情與待辦，推進 App Group，不等資料變動。
    ///
    /// 需要這個是因為上面三個 sync 全都掛在「資料變動」上。一台只用來看、不編輯的裝置
    /// —— 例如都在手機記錄的 Mac —— 永遠不會觸發它們，`shared.mood` / `shared.todos`
    /// 也就從來沒被寫過；Widget、Watch 與桌寵讀到的是「這台機器沒有資料」，而不是
    /// 「今天沒事」，兩者長得一樣但意思完全不同。
    ///
    /// **必須在 `WatchChangeObserver.checkForWatchChanges()` 之後呼叫。** 那個合併是
    /// 同步的，先跑完才能保證這裡讀到的儲存層已經含有 Widget/Watch 那側剛勾掉的項目；
    /// 反過來的話，這裡就會拿舊資料蓋掉還沒合併的外部變更 —— 那正是 `TodoQuadrantStore.load()`
    /// 特地不在冷啟動時存檔的原因。
    @MainActor
    static func pushSnapshotFromStorage() {
        let todos: [TodoItem] = StorageManager.load([TodoItem].self, forKey: "todo_quadrant_v1") ?? []
        syncTodos(todos)

        let points: [MoodPoint] = StorageManager.load([MoodPoint].self, forKey: "mood_history_points_v1") ?? []
        syncMoodEntries(MoodHistoryStore.todayEntries(from: points))
    }

    // MARK: - Todos (待辦事項)

    static func syncTodos(_ items: [TodoItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            defaults.set(data, forKey: SharedConstants.Keys.todos)
            reloadWidgets()
            // 若使用者開了「待辦」即時動態，一併更新島上顯示的那筆（內部會判斷是否開啟）
            TodoLiveActivityController.update()
        } catch {
            debugLog("⚠️ WatchSync: Todos 編碼失敗 - \(error.localizedDescription)")
        }
    }
}
