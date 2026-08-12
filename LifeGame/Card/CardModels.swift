import SwiftUI
import Foundation

// MARK: - CardSize
enum CardSize: String, Codable, CaseIterable {
    case small, medium, large
    
    /// ✅ 新版：依「目前 grid 最大欄數」決定要跨幾欄
    func span(maxColumns: Int) -> Int {
        switch self {
        case .small:
            return 1            // 一格、較矮
        case .medium:
            return 1            // 一格（≈ 原本的卡片尺寸）
        case .large:
            return 1            // 一格、但較高（直式）→ 不再撐滿整排變橫扁
        }
    }
    
    /// ✅ 相容層：舊程式還在用 `.columns` 不會爆
    /// （暫時假設舊版最大 3 欄）
    var columns: Int {
        span(maxColumns: 3)
    }
    
    var height: CGFloat {
        let base: CGFloat = switch self {
        case .small: 110
        case .medium: 160
        case .large: 270
        }
        return base * AppLayout.heightScale
    }
}

// MARK: - CardType

enum CardType: String, CaseIterable, Identifiable, Codable {
    case quickStart
    case todayStatus
    case calendar
    case dailyLog
    case editCards
    case todoQuadrant
    case tomorrowRing
    case bagRequired
    case monthlyScoreCalendar
    case ganttChart
    case copingNotes

    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .quickStart: return String(localized: "快速開始")
        case .todayStatus: return String(localized: "今日狀態")
        case .calendar: return String(localized: "行事曆")
        case .dailyLog: return String(localized: "每日紀錄")
        case .editCards: return String(localized: "編輯卡片")
        case .todoQuadrant: return String(localized: "待辦四象限")
        case .tomorrowRing: return String(localized: "時間圓環")
        case .bagRequired: return String(localized: "整理書包")
        case .monthlyScoreCalendar: return String(localized: "本月結算")
        case .ganttChart: return String(localized: "甘特圖")
        case .copingNotes: return String(localized: "動力筆記")
        }
    }

    var icon: String {
        switch self {
        case .quickStart: return "bolt"
        case .todayStatus: return "heart.text.square"
        case .calendar: return "calendar"
        case .dailyLog: return "square.and.pencil"
        case .editCards: return "square.grid.2x2"
        case .todoQuadrant: return "list.bullet.clipboard"
        case .tomorrowRing: return "clock"
        case .bagRequired: return "backpack"
        case .monthlyScoreCalendar: return "calendar.badge.clock"
        case .ganttChart: return "chart.bar.xaxis"
        case .copingNotes: return "lightbulb.fill"
        }
    }

    var defaultSize: CardSize {
        switch self {
        case .todayStatus: return .medium
        case .calendar: return .large
        case .dailyLog: return .large
        case .quickStart: return .small
        case .editCards: return .small
        case .todoQuadrant: return .large
        case .tomorrowRing: return .large
        case .bagRequired: return .medium
        case .monthlyScoreCalendar: return .large
        case .ganttChart: return .large
        case .copingNotes: return .medium
        }
    }
}

// MARK: - CardItem

// MARK: - CardType → FeatureID 對應

extension CardType {
    /// 這張卡片是否代表可導航的功能（FAB 選單用）
    var isNavigableFeature: Bool {
        featureID != nil
    }

    /// 卡片對應的 FeatureID（非功能型卡片回傳 nil）
    var featureID: FeatureID? {
        switch self {
        case .quickStart:             return nil          // 不是功能入口
        case .todayStatus:            return nil          // 純顯示
        case .editCards:              return nil          // 編輯用，不導航
        case .calendar:               return .calendar
        case .dailyLog:               return .dailyLog
        case .todoQuadrant:           return .todoQuadrant
        case .tomorrowRing:           return .tomorrowRing
        case .bagRequired:            return .bagRequired
        case .monthlyScoreCalendar:   return .monthlyScoreCalendar
        case .ganttChart:             return .ganttChart
        case .copingNotes:            return .copingNotes
        }
    }
}

// MARK: - CardItem

struct CardItem: Identifiable, Codable, Equatable {
    var type: CardType
    var size: CardSize

    var id: String { type.rawValue }
}

// MARK: - Safe Array Decoding

extension Array where Element == CardItem {
    /// 解碼時跳過未知的 CardType（向後相容舊版 app）
    init(safeDecoding decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var items: [CardItem] = []
        while !container.isAtEnd {
            if let item = try? container.decode(CardItem.self) {
                items.append(item)
            } else {
                // 跳過無法解碼的項目（例如新版新增的 enum case）
                _ = try? container.decode(AnyCodable.self)
            }
        }
        self = items
    }
}

/// 用於跳過無法解碼的 JSON 值
private struct AnyCodable: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { return }
        if let _ = try? container.decode(Bool.self) { return }
        if let _ = try? container.decode(Int.self) { return }
        if let _ = try? container.decode(Double.self) { return }
        if let _ = try? container.decode(String.self) { return }
        if let _ = try? container.decode([AnyCodable].self) { return }
        if let _ = try? container.decode([String: AnyCodable].self) { return }
    }
    func encode(to encoder: Encoder) throws {}
}
