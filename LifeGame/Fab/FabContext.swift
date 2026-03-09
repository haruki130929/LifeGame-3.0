import Foundation

enum FeatureID: Hashable {
    case diary
    case calendar
    case wish
    case ledger
    case settings
    // ── 新增：對應 SlotCard 卡片 ──
    case dailyLog
    case todoQuadrant
    case tomorrowRing
    case bagRequired
    case monthlyScoreCalendar
    case moodThermometer
}

enum FabContext {
    case home(timeSlot: TimeSlot, features: [FeatureID])
    case feature(FeatureID)
}
