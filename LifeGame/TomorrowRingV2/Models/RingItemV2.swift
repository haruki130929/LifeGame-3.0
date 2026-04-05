import Foundation

// MARK: - RingItemV2

struct RingItemV2: Identifiable, Codable, Hashable {
    var id = UUID()
    var startMinute: Int          // 0..<1440
    var endMinute: Int            // 0..<1440, can wrap past midnight
    var title: String
    var icon: String              // SF Symbol name
    var colorHex: String          // 6-char hex e.g. "FF6B6B"
    var hpCost: Int = 0
    var fpCost: Int = 0
    var source: Source = .manual

    enum Source: String, Codable, Hashable {
        case manual
        case schedule
        case classSchedule
    }

    /// Duration in minutes, correctly handling midnight wrap.
    var duration: Int {
        let d = endMinute - startMinute
        return d >= 0 ? d : d + RingTimeHelpers.totalMinutes
    }
}

// MARK: - Migration from V1

extension RingItemV2 {
    /// Convert a V1 RingItem to V2.
    init(from v1: RingItem) {
        self.id = v1.id
        self.startMinute = v1.startMinute
        self.endMinute = v1.endMinute
        self.title = v1.title
        self.icon = v1.icon
        self.colorHex = v1.colorHex
        self.hpCost = v1.hpCost
        self.fpCost = v1.fpCost
        self.source = v1.isFromSchedule ? .schedule : .manual
    }
}
