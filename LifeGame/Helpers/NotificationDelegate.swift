import Foundation
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationDelegate()
    
    /// App 在前景時也要顯示 banner，就靠這個
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        debugLog("✅ willPresent called:", notification.request.identifier)
        completionHandler([.banner, .list, .sound, .badge])
    }
}
