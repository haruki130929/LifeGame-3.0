//
//  LiveActivityController.swift
//  LifeGame
//
//  控制「今日狀態」Live Activity 的啟動／更新／結束。
//  開關偏好存在 App Group，讓 WatchSyncHelper.syncStats 在更新前能判斷是否該推送。
//

import Foundation
#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit
#endif

enum LiveActivityController {

    private static let enabledKey = "liveActivity.todayStatus.enabled"

    /// 使用者是否在設定頁開啟了「今日狀態」即時動態。
    static var isEnabled: Bool {
        get { SharedConstants.sharedDefaults.bool(forKey: enabledKey) }
        set { SharedConstants.sharedDefaults.set(newValue, forKey: enabledKey) }
    }

    /// 今天結束（隔天 00:00）—— 當 staleDate，跨日後讓系統自然淡出。
    private static var endOfToday: Date {
        Calendar.current.startOfDay(for: Date()).addingTimeInterval(24 * 3600)
    }

    // MARK: - 對外 API

    /// 設定頁開關「開」時呼叫：記住偏好並啟動活動（需在前景）。
    static func start() {
        isEnabled = true
        #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            debugLog("⚠️ 使用者未允許即時動態（系統設定）")
            return
        }
        // 已經有一個進行中就不重複開，改成更新
        guard Activity<TodayStatusAttributes>.activities.isEmpty else {
            refresh()
            return
        }
        guard let state = currentState() else {
            debugLog("⚠️ 尚無 stats 快照，無法啟動 Live Activity")
            return
        }
        do {
            _ = try Activity.request(
                attributes: TodayStatusAttributes(),
                content: .init(state: state, staleDate: endOfToday)
            )
            debugLog("✅ 已啟動今日狀態 Live Activity")
        } catch {
            debugLog("⚠️ Live Activity 啟動失敗：\(error)")
        }
        #endif
    }

    /// 設定頁開關「關」時呼叫：記住偏好並結束所有活動。
    static func stop() {
        isEnabled = false
        #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
        Task {
            for activity in Activity<TodayStatusAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            debugLog("🛑 已結束今日狀態 Live Activity")
        }
        #endif
    }

    /// stats 變動時由 WatchSyncHelper.syncStats 呼叫：開著才更新內容。
    static func update(hp: Stat, fp: Stat, mp: Stat) {
        #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
        guard isEnabled else { return }
        pushState(TodayStatusAttributes.ContentState(
            hp: hp.current, hpMax: hp.max,
            fp: fp.current, fpMax: fp.max,
            mp: mp.current, mpMax: mp.max
        ))
        #endif
    }

    /// App 回前景時呼叫：若「開著」卻沒有進行中的活動（全新安裝尚無快照、被系統清掉、
    /// 過了 staleDate 被淡出移除），就重新釘上；已有的話補一次最新數值。
    static func reconcile() {
        #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
        guard isEnabled else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if Activity<TodayStatusAttributes>.activities.isEmpty {
            start()       // 內部會在有 stats 快照時 request；沒有就略過、等下次
        } else {
            refresh()     // 補一次最新數值
        }
        #endif
    }

    // MARK: - Helpers

    #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
    /// 用目前 shared.stats 的快照更新（啟動後立即補一次）。
    private static func refresh() {
        guard let state = currentState() else { return }
        pushState(state)
    }

    private static func pushState(_ state: TodayStatusAttributes.ContentState) {
        Task {
            for activity in Activity<TodayStatusAttributes>.activities {
                await activity.update(.init(state: state, staleDate: endOfToday))
            }
        }
    }

    /// 從 App Group 的 shared.stats 讀目前 HP/FP/MP。
    private static func currentState() -> TodayStatusAttributes.ContentState? {
        guard let data = SharedConstants.sharedDefaults.data(forKey: SharedConstants.Keys.stats),
              let p = try? JSONDecoder().decode(SyncStatsPayload.self, from: data) else { return nil }
        return TodayStatusAttributes.ContentState(
            hp: p.hp.current, hpMax: p.hp.max,
            fp: p.fp.current, fpMax: p.fp.max,
            mp: p.mp.current, mpMax: p.mp.max
        )
    }
    #endif
}

// MARK: - 待辦 Live Activity 控制器

/// 控制「待辦」Live Activity（靈動島／鎖定畫面，含「完成」互動鈕）。
/// 顯示哪一筆、要不要結束，都由 TodoLiveActivityShared 依 App Group 的 shared.todos 決定。
enum TodoLiveActivityController {

    private static let enabledKey = "liveActivity.todo.enabled"

    static var isEnabled: Bool {
        get { SharedConstants.sharedDefaults.bool(forKey: enabledKey) }
        set { SharedConstants.sharedDefaults.set(newValue, forKey: enabledKey) }
    }

    /// 設定頁開關「開」：記住偏好並啟動（顯示最近要到期的未完成待辦）。
    static func start() {
        isEnabled = true
        #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            debugLog("⚠️ 使用者未允許即時動態（系統設定）")
            return
        }
        guard Activity<TodoActivityAttributes>.activities.isEmpty else { refresh(); return }
        guard let state = TodoLiveActivityShared.currentState() else {
            debugLog("ℹ️ 目前沒有未完成待辦，待辦 Live Activity 不啟動")
            return
        }
        do {
            _ = try Activity.request(
                attributes: TodoActivityAttributes(),
                content: .init(state: state, staleDate: nil)
            )
            debugLog("✅ 已啟動待辦 Live Activity")
        } catch {
            debugLog("⚠️ 待辦 Live Activity 啟動失敗：\(error)")
        }
        #endif
    }

    /// 設定頁開關「關」：記住偏好並結束所有活動。
    static func stop() {
        isEnabled = false
        #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
        Task {
            for activity in Activity<TodoActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            debugLog("🛑 已結束待辦 Live Activity")
        }
        #endif
    }

    /// 待辦變動時呼叫（WatchSyncHelper.syncTodos）：開著才更新成最新的「該顯示那筆」。
    static func update() {
        #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
        guard isEnabled else { return }
        Task {
            if let state = TodoLiveActivityShared.currentState() {
                let activities = Activity<TodoActivityAttributes>.activities
                if activities.isEmpty {
                    start()   // 開著但沒活動（先前全做完後又新增）→ 重新開
                } else {
                    // 狀態沒變就不重推，避免回前景時多餘的更新／島閃動
                    for activity in activities where activity.content.state != state {
                        await activity.update(.init(state: state, staleDate: nil))
                    }
                }
            } else {
                // 沒有未完成待辦 → 結束
                for activity in Activity<TodoActivityAttributes>.activities {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
        }
        #endif
    }

    /// App 回前景時呼叫：補釘 / 換最新一筆 / 沒待辦就結束。
    static func reconcile() {
        #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
        guard isEnabled else { return }
        update()
        #endif
    }

    #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
    private static func refresh() {
        guard let state = TodoLiveActivityShared.currentState() else { return }
        Task {
            for activity in Activity<TodoActivityAttributes>.activities where activity.content.state != state {
                await activity.update(.init(state: state, staleDate: nil))
            }
        }
    }
    #endif
}
