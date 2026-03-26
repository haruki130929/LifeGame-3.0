import Foundation

enum FeatureID: String, Hashable, Identifiable {
    var id: String { rawValue }

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
    case mandala
    case practiceDiary
}

enum FabContext {
    case home(timeSlot: TimeSlot, features: [FeatureID])
    case feature(FeatureID)
}
