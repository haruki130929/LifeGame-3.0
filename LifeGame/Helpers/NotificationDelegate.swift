import Foundation
import UserNotifications
#if canImport(WidgetKit)
import WidgetKit
#endif

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationDelegate()

    /// App 在前景時也要顯示 banner，就靠這個
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        debugLog("✅ willPresent called:", notification.request.identifier)
        completionHandler([.banner, .list, .sound, .badge])
    }

    /// 使用者按了通知上的動作按鈕。
    /// 這裡只做「寫進 App Group」這個耐久動作（不碰 @MainActor 的 store），
    /// App 下次回前景時 WatchChangeObserver.checkForWatchChanges() 會自動合併回真正的 store
    /// —— 與 Widget／Watch 完全相同的寫回 → 合併路徑。
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        let request = response.notification.request
        let category = request.content.categoryIdentifier
        let action = response.actionIdentifier

        switch (category, action) {

        // 待辦「完成」
        case (NotificationManager.Category.todoDue, NotificationManager.Action.completeTodo):
            if let id = request.content.userInfo["todoID"] as? String {
                NotificationActionBridge.completeTodo(id: id)
                center.removeDeliveredNotifications(withIdentifiers: [request.identifier])
            }

        // 心情「輸入 0–10」
        case (NotificationManager.Category.hourlyMood, NotificationManager.Action.logMood):
            if let textResponse = response as? UNTextInputNotificationResponse {
                let input = textResponse.userText.trimmingCharacters(in: .whitespacesAndNewlines)
                if let value = Int(input), (0...10).contains(value) {
                    // 用「通知送達時間」回推上一小時，比用回覆當下更準（避免整點 off-by-one）
                    let targetHour = response.notification.date.addingTimeInterval(-3600)
                    NotificationActionBridge.logMood(value: value, forHour: targetHour)
                } else {
                    debugLog("⚠️ 心情輸入無效：\(input)")
                }
            }

        default:
            break   // 預設點擊／滑掉 → 交給系統（通常會打開 App）
        }

        completionHandler()
    }
}

/// 把通知動作的結果寫進 App Group —— 與 Widget／Watch 共用同一條寫回通道。
/// 這些方法只用 UserDefaults + Codable，不碰 @MainActor 的 store，
/// 可安全在通知的背景情境（甚至 App 被系統喚醒）執行。
enum NotificationActionBridge {

    /// 待辦打勾：邏輯同 TodoWidget 的 WidgetTodoBridge.markDone
    static func completeTodo(id: String) {
        let defaults = SharedConstants.sharedDefaults
        guard let uuid = UUID(uuidString: id),
              let data = defaults.data(forKey: SharedConstants.Keys.todos),
              var items = try? JSONDecoder().decode([TodoItem].self, from: data),
              let idx = items.firstIndex(where: { $0.id == uuid }),
              items[idx].isDone == false
        else { return }

        items[idx].isDone = true
        guard let newData = try? JSONEncoder().encode(items) else { return }
        defaults.set(newData, forKey: SharedConstants.Keys.todos)
        // bump 時間戳 → App 回前景時 WatchChangeObserver 會合併回 store
        defaults.set(Date().timeIntervalSince1970, forKey: SharedConstants.Keys.watchTodosUpdatedAt)
        reloadWidgets()   // 讓桌面「待辦」Widget 立即反映已完成
        debugLog("✅ 通知完成待辦：\(id)")
    }

    /// 記錄心情 0–10：邏輯同 Watch 的 saveMood（寫 shared.mood + bump 時間戳）
    static func logMood(value: Int, forHour date: Date) {
        let clamped = min(10, max(0, value))
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH"
        let hourKey = fmt.string(from: date)
        let entry = MoodEntry(id: hourKey, hourKey: hourKey, value: clamped)

        let defaults = SharedConstants.sharedDefaults
        var entries: [MoodEntry] = defaults.data(forKey: SharedConstants.Keys.mood)
            .flatMap { try? JSONDecoder().decode([MoodEntry].self, from: $0) } ?? []

        // 同一小時覆寫，沒有就新增（與 MoodHistoryStore.mergeFromWatch 一致）
        if let idx = entries.firstIndex(where: { $0.hourKey == hourKey }) {
            entries[idx] = entry
        } else {
            entries.append(entry)
        }
        guard let newData = try? JSONEncoder().encode(entries) else { return }
        defaults.set(newData, forKey: SharedConstants.Keys.mood)
        defaults.set(Date().timeIntervalSince1970, forKey: SharedConstants.Keys.watchMoodUpdatedAt)
        reloadWidgets()
        debugLog("✅ 通知記錄心情：\(clamped) @ \(hourKey)")
    }

    private static func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
