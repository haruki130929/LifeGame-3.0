import Foundation
import Combine
import SwiftUI
import Combine

@MainActor
final class CalendarSettingsStore: ObservableObject {
    private enum Keys {
        static let firstWeekday = "calendar_firstWeekday"
        static let syncAppleCalendar = "calendar_syncAppleCalendar"
    }

    /// 1=週日, 2=週一...7=週六（預設週日）
    @Published var firstWeekday: Int = 1 {
        didSet {
            StorageManager.save(firstWeekday, forKey: Keys.firstWeekday)
        }
    }

    /// 是否同步 Apple 內建行事曆
    @Published var syncAppleCalendar: Bool = false {
        didSet {
            StorageManager.save(syncAppleCalendar, forKey: Keys.syncAppleCalendar)
        }
    }

    init() {
        firstWeekday = StorageManager.load(Int.self, forKey: Keys.firstWeekday) ?? 1
        syncAppleCalendar = StorageManager.load(Bool.self, forKey: Keys.syncAppleCalendar) ?? false
    }
    
    var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "zh_TW")
        cal.timeZone = .current
        cal.firstWeekday = firstWeekday
        return cal
    }
}
