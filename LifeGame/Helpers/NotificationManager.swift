import Foundation
import UserNotifications

enum NotificationManager {
    
    // MARK: - IDs
    static let settleReminderID = "daily_settle_reminder"

    // MARK: - Categories & Actions（互動通知）

    enum Category {
        static let todoDue = "todo_due_category"
        static let hourlyMood = "hourly_mood_category"
    }
    enum Action {
        static let completeTodo = "complete_todo"
        static let logMood = "log_mood"
    }

    /// 註冊互動通知的分類與動作按鈕。App 啟動時呼叫一次即可
    /// （setNotificationCategories 會整批覆寫，不要在每次排程時呼叫）。
    static func setupNotificationCategories() {
        // 待辦到期 → 一顆「完成」按鈕，背景處理、不開 App
        let complete = UNNotificationAction(
            identifier: Action.completeTodo,
            title: "完成",
            options: []
        )
        let todoCategory = UNNotificationCategory(
            identifier: Category.todoDue,
            actions: [complete],
            intentIdentifiers: [],
            options: []
        )

        // 心情提醒 → 直接在通知裡輸入 0–10，背景記錄、不開 App
        let logMood = UNTextInputNotificationAction(
            identifier: Action.logMood,
            title: "記錄心情",
            options: [],
            textInputButtonTitle: "記錄",
            textInputPlaceholder: "0–10"
        )
        let moodCategory = UNNotificationCategory(
            identifier: Category.hourlyMood,
            actions: [logMood],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([todoCategory, moodCategory])
    }

    // MARK: - Permission
    /// 需要時才詢問權限，並把結果回傳
    static func requestPermissionIfNeeded(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(true)
                
            case .denied:
                completion(false)
                
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    completion(granted)
                }
                
            @unknown default:
                completion(false)
            }
        }
    }
    
    /// 開啟開關或改時間時用：確保有權限才排「每日提醒」
    static func ensurePermissionThenScheduleDaily(hour: Int, minute: Int, onDenied: @escaping () -> Void) {
        requestPermissionIfNeeded { granted in
            DispatchQueue.main.async {
                if granted {
                    scheduleDailySettleReminder(hour: hour, minute: minute)
                } else {
                    onDenied()
                }
            }
        }
    }
    
    // MARK: - Daily reminder
    static func scheduleDailySettleReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        
        // 先移除舊的避免重複
        center.removePendingNotificationRequests(withIdentifiers: [settleReminderID])
        
        let content = UNMutableNotificationContent()
        content.title = "今日結算提醒"
        content.body = "今天要不要按一下「今日結算」"
        content.sound = .default
        
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let req = UNNotificationRequest(identifier: settleReminderID, content: content, trigger: trigger)
        
        center.add(req) { err in
            if let err = err {
                debugLog("❌ scheduleDailySettleReminder error:", err)
            } else {
                debugLog("✅ scheduled daily \(String(format: "%02d:%02d", hour, minute))")
            }
        }
    }
    
    static func cancelDailySettleReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [settleReminderID])
        debugLog("🗑️ canceled daily reminder")
    }
    
    // MARK: - Debug / Test
    static func debugPrintAuthStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            debugLog("🔐 auth =", s.authorizationStatus.rawValue,
                  "alert =", s.alertSetting.rawValue,
                  "sound =", s.soundSetting.rawValue,
                  "badge =", s.badgeSetting.rawValue)
        }
    }
    
    static func debugPrintPending() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            debugLog("📌 Pending notifications:")
            reqs.forEach { debugLog("•", $0.identifier, $0.trigger ?? "") }
        }
    }
    
    /// 前景/背景都能測：10 秒後跳一個通知
    static func scheduleTestIn10Seconds() {
        requestPermissionIfNeeded { granted in
            guard granted else {
                debugLog("❌ no permission")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "測試通知"
            content.body = "10 秒測試"
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            let req = UNNotificationRequest(
                identifier: "test_10s_\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(req) { err in
                if let err = err {
                    debugLog("❌ scheduleTestIn10Seconds error:", err)
                } else {
                    debugLog("✅ scheduled test in 10s")
                }
            }
        }
    }
    /// 測試用：N 秒後跳一個「待辦完成」互動通知（複用 todoDue 分類 → 通知上會有「完成」按鈕）。
    static func scheduleTodoCompletionTest(todoID: String, title: String, after seconds: TimeInterval = 5) {
        requestPermissionIfNeeded { granted in
            guard granted else {
                debugLog("❌ scheduleTodoCompletionTest: 無通知權限")
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "待辦提醒（測試）"
            content.body = "「\(title)」做完了嗎？"
            content.sound = .default
            content.categoryIdentifier = Category.todoDue          // → 通知上出現「完成」按鈕
            content.userInfo = ["todoID": todoID]                  // → 按完成時定位這筆待辦

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
            let req = UNNotificationRequest(
                identifier: "todo_test_\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(req) { err in
                if let err {
                    debugLog("❌ scheduleTodoCompletionTest error:", err)
                } else {
                    debugLog("✅ 測試通知已排程（\(Int(seconds)) 秒後）")
                }
            }
        }
    }

    static let hourlyMoodReminderID = "hourly_mood_reminder"
    
    static func scheduleHourlyMoodReminder(minute: Int = 0) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [hourlyMoodReminderID])
        
        let content = UNMutableNotificationContent()
        content.title = "心情溫度計提醒"
        content.body = "補記上一小時的心情（0～10）"
        content.sound = .default
        content.categoryIdentifier = Category.hourlyMood   // → 通知內可直接輸入 0–10

        var comps = DateComponents()
        comps.minute = minute   // 例如 00：整點；05：每小時 05 分
        comps.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(
            identifier: hourlyMoodReminderID,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
    
    static func cancelHourlyMoodReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [hourlyMoodReminderID])
    }

    // MARK: - 待辦截止提醒

    /// 排程待辦到期通知
    static func scheduleTodoReminder(id: UUID, title: String, dueDate: Date) {
        let center = UNUserNotificationCenter.current()
        let identifier = "todo_due_\(id.uuidString)"

        // 移除舊的（更新截止日期時）
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        // 如果到期時間已過，不排程
        guard dueDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "待辦到期"
        content.body = title
        content.sound = .default
        content.categoryIdentifier = Category.todoDue          // → 通知上出現「完成」按鈕
        content.userInfo = ["todoID": id.uuidString]           // → 動作處理器用來定位待辦

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(req) { err in
            if let err = err {
                debugLog("❌ scheduleTodoReminder error:", err)
            } else {
                debugLog("✅ scheduled todo reminder: \(title) at \(dueDate)")
            }
        }
    }

    /// 取消待辦到期通知
    static func cancelTodoReminder(id: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["todo_due_\(id.uuidString)"])
    }
}
