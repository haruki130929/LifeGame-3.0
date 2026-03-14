import Foundation

// MARK: - QuickFeatureType

/// 簡略模式中可選用的功能類型
enum QuickFeatureType: String, Codable, CaseIterable, Identifiable {
    case bag
    case mood
    case todo
    case dailyLog
    case calendar
    case tomorrowRing
    case monthlyScore
    case diary
    case finance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bag:            return "收拾書包"
        case .mood:           return "心情溫度計"
        case .todo:           return "待辦四象限"
        case .dailyLog:       return "每日紀錄"
        case .calendar:       return "行事曆"
        case .tomorrowRing:   return "時間圓環"
        case .monthlyScore:   return "本月結算"
        case .diary:          return "日記"
        case .finance:        return "財務"
        }
    }

    var icon: String {
        switch self {
        case .bag:            return "backpack"
        case .mood:           return "heart.text.square"
        case .todo:           return "list.bullet.clipboard"
        case .dailyLog:       return "square.and.pencil"
        case .calendar:       return "calendar"
        case .tomorrowRing:   return "clock"
        case .monthlyScore:   return "calendar.badge.clock"
        case .diary:          return "book"
        case .finance:        return "yensign.circle"
        }
    }

    /// 對應的 FeatureID（供 FAB context 使用）
    var featureID: FeatureID {
        switch self {
        case .bag:            return .bagRequired
        case .mood:           return .moodThermometer
        case .todo:           return .todoQuadrant
        case .dailyLog:       return .dailyLog
        case .calendar:       return .calendar
        case .tomorrowRing:   return .tomorrowRing
        case .monthlyScore:   return .monthlyScoreCalendar
        case .diary:          return .diary
        case .finance:        return .wish
        }
    }
}

// MARK: - QuickPage

/// 簡略模式中的一個頁面
struct QuickPage: Identifiable, Codable, Equatable {
    let id: UUID
    var featureType: QuickFeatureType
    var order: Int

    init(id: UUID = UUID(), featureType: QuickFeatureType, order: Int) {
        self.id = id
        self.featureType = featureType
        self.order = order
    }
}
