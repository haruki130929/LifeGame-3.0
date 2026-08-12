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
            title: String(localized: "完成"),
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
            title: String(localized: "記錄心情"),
            options: [],
            textInputButtonTitle: String(localized: "記錄"),
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
    
    // MARK: - 語言切換後重排

    /// 通知的文字是「排程當下」就寫死進 UNMutableNotificationContent 的，而「每日結算」與
    /// 「每小時心情」兩個提醒都是 repeats: true —— 使用者換語言之後若不重排，
    /// 它們會永遠用舊語言跳出來。
    ///
    /// 這裡在啟動時比對「上次排程時的語言」，不同才重排。重排是以相同 identifier 覆寫，
    /// 冪等且安全。動作按鈕標題不需處理：setupNotificationCategories() 每次啟動都會重新註冊。
    ///
    /// 待辦到期提醒（todo_due_*）的標題同樣是排程當下寫死的，也會一併重排 ——
    /// 那批綁定的是各自的到期時間，不重排的話換語言後好幾天內都還會跳出舊語言的通知。
    static func refreshLocalizedRemindersIfLanguageChanged() {
        let languageKey = "notifications.localizedFor_v1"
        let current = Bundle.main.preferredLocalizations.first ?? "zh-Hant"
        let previous = UserDefaults.standard.string(forKey: languageKey)

        guard previous != current else { return }

        // 儲存層還沒就緒時，下面讀開關一律拿到 nil，會靜靜地不重排。
        // 若此時就把語言標記更新掉，下次啟動就會因為「語言沒變」而永遠不再重排，
        // 通知會一直卡在舊語言。所以還沒就緒就直接返回，留到下次啟動再處理。
        guard StorageManager.coordinator != nil else { return }

        UserDefaults.standard.set(current, forKey: languageKey)
        guard previous != nil else { return }   // 首次啟動沒有舊排程，不必重排

        if StorageManager.load(Bool.self, forKey: "settleReminderEnabled_v1") ?? false {
            let hour = StorageManager.load(Int.self, forKey: "settleReminderHour") ?? 22
            let minute = StorageManager.load(Int.self, forKey: "settleReminderMinute") ?? 0
            scheduleDailySettleReminder(hour: hour, minute: minute)
        }
        if StorageManager.load(Bool.self, forKey: "hourlyMoodReminderEnabled_v1") ?? false {
            scheduleHourlyMoodReminder(minute: 0)
        }
        relocalizePendingTodoReminders()
        debugLog("🌐 語言由 \(previous ?? "-") 改為 \(current)，已重排通知")
    }

    /// 把已排程的待辦到期通知改用新語言的標題重排。
    ///
    /// 待辦名稱（body）是使用者資料，原樣保留；只有「待辦到期」這個標題要換語言。
    /// pending request 本身就帶著 trigger / body / userInfo，用相同 identifier 重新 add
    /// 即覆寫，冪等，不需要回頭去碰 TodoStore。
    private static func relocalizePendingTodoReminders() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let todos = requests.filter { $0.identifier.hasPrefix("todo_due_") }
            guard !todos.isEmpty else { return }

            for old in todos {
                let content = UNMutableNotificationContent()
                content.title = String(localized: "待辦到期")
                content.body = old.content.body
                content.sound = old.content.sound
                content.categoryIdentifier = old.content.categoryIdentifier
                content.userInfo = old.content.userInfo
                center.add(UNNotificationRequest(identifier: old.identifier,
                                                 content: content,
                                                 trigger: old.trigger))
            }
            debugLog("🌐 已用新語言重排 \(todos.count) 則待辦到期通知")
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
        content.title = String(localized: "今日結算提醒")
        content.body = String(localized: "今天要不要按一下「今日結算」")
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
            content.title = String(localized: "測試通知")
            content.body = String(localized: "10 秒測試")
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

    static let hourlyMoodReminderID = "hourly_mood_reminder"
    
    static func scheduleHourlyMoodReminder(minute: Int = 0) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [hourlyMoodReminderID])
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "心情溫度計提醒")
        content.body = String(localized: "補記上一小時的心情（0～10）")
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
        content.title = String(localized: "待辦到期")
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
