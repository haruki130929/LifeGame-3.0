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
    case ganttChart

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bag:            return "整理書包"
        case .mood:           return "心情溫度計"
        case .todo:           return "待辦四象限"
        case .dailyLog:       return "每日紀錄"
        case .calendar:       return "行事曆"
        case .tomorrowRing:   return "時間圓環"
        case .monthlyScore:   return "本月結算"
        case .diary:          return "日記"
        case .finance:        return "財務"
        case .ganttChart:     return "甘特圖"
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
        case .ganttChart:     return "chart.bar.xaxis"
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
        case .ganttChart:     return .ganttChart
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

// MARK: - Safe Decoding Wrapper

/// 解碼時跳過未知的 QuickFeatureType（向後相容舊版 app）
struct SafeQuickPage: Codable {
    let id: UUID
    let featureTypeRaw: String
    let order: Int

    enum CodingKeys: String, CodingKey {
        case id, featureType, order
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        featureTypeRaw = try container.decode(String.self, forKey: .featureType)
        order = try container.decode(Int.self, forKey: .order)
    }

    func encode(to encoder: Encoder) throws {}

    func toQuickPage() -> QuickPage? {
        guard let type = QuickFeatureType(rawValue: featureTypeRaw) else { return nil }
        return QuickPage(id: id, featureType: type, order: order)
    }
}
