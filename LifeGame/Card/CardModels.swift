import SwiftUI
import Foundation

// MARK: - CardSize
enum CardSize: String, Codable, CaseIterable {
    case small, medium, large
    
    /// ✅ 新版：依「目前 grid 最大欄數」決定要跨幾欄
    func span(maxColumns: Int) -> Int {
        switch self {
        case .small:
            return 1
        case .medium:
            return min(2, maxColumns)
        case .large:
            return maxColumns
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

    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .quickStart: return "快速開始"
        case .todayStatus: return "今日狀態"
        case .calendar: return "行事曆"
        case .dailyLog: return "每日紀錄"
        case .editCards: return "編輯卡片"
        case .todoQuadrant: return "待辦四象限"
        case .tomorrowRing: return "時間圓環"
        case .bagRequired: return "整理書包"
        case .monthlyScoreCalendar: return "本月結算"
        case .ganttChart: return "甘特圖"
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
        }
    }
}

// MARK: - CardItem

struct CardItem: Identifiable, Codable, Equatable {
    var type: CardType
    var size: CardSize

    var id: String { type.rawValue }
}
