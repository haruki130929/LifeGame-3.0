//
//  TodayStatusAttributes.swift
//  LifeGameWidget（共用：需同時加入 App 與 Widget Extension 兩個 target）
//
//  Live Activity 的共用型別。App 端用 ActivityKit 啟動／更新，Widget Extension 端用
//  同一個型別宣告鎖定畫面／動態島的 UI —— 兩邊必須是「同一個型別」，所以這個檔案
//  要同時屬於 LifeGame 與 LifeGameWidgetExtension 兩個 target。
//
//  這裡放兩個 Live Activity：
//   ① TodayStatusAttributes —— 今日狀態（HP/FP/MP，純顯示）
//   ② TodoActivityAttributes —— 待辦（靈動島／鎖定畫面，含「完成」互動鈕）
//

import Foundation

// Live Activities 在 Mac Catalyst 不支援（ActivityKit 的型別被標為 unavailable），
// 整段在 Catalyst 上排除編譯。canImport 在 Catalyst 仍為 true，故必須加 macCatalyst 條件。
#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit
import AppIntents
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - ① 今日狀態

@available(iOS 16.1, *)
struct TodayStatusAttributes: ActivityAttributes {
    /// 會即時變動的部分：HP / FP / MP 的目前值與上限。
    public struct ContentState: Codable, Hashable {
        var hp: Int
        var hpMax: Int
        var fp: Int
        var fpMax: Int
        var mp: Int
        var mpMax: Int
    }
}

// MARK: - ② 待辦 Live Activity

@available(iOS 16.1, *)
struct TodoActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var todoID: String
        var title: String
        var dueText: String     // 例如「今天 18:00 到期」；無截止日則為空字串
        var remaining: Int      // 還有幾筆未完成（含這筆）
    }
}

/// 與 app / widget 端 TodoItem 的 Codable JSON 結構一致（用來在 App Group 讀寫 shared.todos）。
/// 刻意內聯一份，讓這個共用檔在兩個 target 都能獨立編譯。
private struct LATodo: Codable {
    var id: UUID
    var title: String
    var quadrant: Int          // TodoQuadrant 是 Int enum，JSON 就是原始 Int
    var isDone: Bool
    var createdAt: Date
    var startDate: Date?
    var dueDate: Date?
}

/// 待辦 Live Activity 的共用邏輯：只用 App Group + ActivityKit，App 與 Widget 兩端都可呼叫。
@available(iOS 16.1, *)
enum TodoLiveActivityShared {
    static let appGroupID = "group.com.haruki.lifegame"
    static let todosKey = "shared.todos"
    static let updatedAtKey = "shared.watchTodosUpdatedAt"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    private static func loadTodos() -> [LATodo] {
        guard let d = defaults, let data = d.data(forKey: todosKey),
              let items = try? JSONDecoder().decode([LATodo].self, from: data) else { return [] }
        return items
    }

    /// 要顯示在島上的那一筆：未完成中「最近要到期」優先，其次「最新建立」。沒有未完成則回 nil。
    static func currentState() -> TodoActivityAttributes.ContentState? {
        let undone = loadTodos().filter { !$0.isDone }
        guard !undone.isEmpty else { return nil }

        let withDue = undone
            .filter { $0.dueDate != nil }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        let pick = withDue.first ?? undone.sorted { $0.createdAt > $1.createdAt }[0]

        return TodoActivityAttributes.ContentState(
            todoID: pick.id.uuidString,
            title: pick.title,
            dueText: dueText(for: pick.dueDate),
            remaining: undone.count
        )
    }

    /// 在 App Group 把某筆標記完成 + bump 時間戳（邏輯同 widget 打勾，App 回前景會合併回 store）。
    static func markDone(todoID: String) {
        guard let d = defaults, let uuid = UUID(uuidString: todoID),
              let data = d.data(forKey: todosKey),
              var items = try? JSONDecoder().decode([LATodo].self, from: data),
              let idx = items.firstIndex(where: { $0.id == uuid }), !items[idx].isDone else { return }
        items[idx].isDone = true
        guard let newData = try? JSONEncoder().encode(items) else { return }
        d.set(newData, forKey: todosKey)
        d.set(Date().timeIntervalSince1970, forKey: updatedAtKey)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    private static func dueText(for date: Date?) -> String {
        guard let date else { return "" }
        let cal = Calendar.current
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        let time = f.string(from: date)
        if cal.isDateInToday(date) { return String(localized: "今天 \(time) 到期") }
        if cal.isDateInTomorrow(date) { return String(localized: "明天 \(time) 到期") }
        f.dateFormat = "M/d HH:mm"
        return String(localized: "\(f.string(from: date)) 到期")
    }
}

/// 靈動島／鎖定畫面上的「完成」按鈕用的互動 Intent。
/// 用 LiveActivityIntent → perform 在 App 程序執行，可直接更新／結束 Live Activity。
@available(iOS 17.0, *)
struct CompleteTodoFromLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "完成待辦"

    @Parameter(title: "Todo ID") var todoID: String

    init() {}
    init(todoID: String) { self.todoID = todoID }

    func perform() async throws -> some IntentResult {
        TodoLiveActivityShared.markDone(todoID: todoID)
        // 標記完成後：有下一筆未完成 → 換成它；沒有 → 結束活動
        if let next = TodoLiveActivityShared.currentState() {
            for activity in Activity<TodoActivityAttributes>.activities {
                await activity.update(.init(state: next, staleDate: nil))
            }
        } else {
            for activity in Activity<TodoActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        return .result()
    }
}
#endif
