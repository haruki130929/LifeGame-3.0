import Foundation
import SwiftUI

@MainActor
final class CalendarSettingsStore: ObservableObject {
    /// 1=週日, 2=週一...7=週六（預設週日）
    @AppStorage("calendar_firstWeekday") var firstWeekday: Int = 1
    
    var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "zh_TW")
        cal.timeZone = .current
        cal.firstWeekday = firstWeekday
        return cal
    }
}
