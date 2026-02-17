import Foundation
import UserNotifications

enum NotificationManager {
    
    // MARK: - IDs
    static let settleReminderID = "daily_settle_reminder"
    
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
                print("❌ scheduleDailySettleReminder error:", err)
            } else {
                print("✅ scheduled daily \(String(format: "%02d:%02d", hour, minute))")
            }
        }
    }
    
    static func cancelDailySettleReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [settleReminderID])
        print("🗑️ canceled daily reminder")
    }
    
    // MARK: - Debug / Test
    static func debugPrintAuthStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            print("🔐 auth =", s.authorizationStatus.rawValue,
                  "alert =", s.alertSetting.rawValue,
                  "sound =", s.soundSetting.rawValue,
                  "badge =", s.badgeSetting.rawValue)
        }
    }
    
    static func debugPrintPending() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            print("📌 Pending notifications:")
            reqs.forEach { print("•", $0.identifier, $0.trigger ?? "") }
        }
    }
    
    /// 前景/背景都能測：10 秒後跳一個通知
    static func scheduleTestIn10Seconds() {
        requestPermissionIfNeeded { granted in
            guard granted else {
                print("❌ no permission")
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
                    print("❌ scheduleTestIn10Seconds error:", err)
                } else {
                    print("✅ scheduled test in 10s")
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
}
