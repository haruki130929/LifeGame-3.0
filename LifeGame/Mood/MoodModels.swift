import Foundation

struct MoodEntry: Identifiable, Codable, Equatable {
    var id: String              // 用 hourKey 當 id，方便覆寫
    var hourKey: String         // "yyyy-MM-dd HH"（例如 2025-12-27 20）
    var value: Int              // 0...10
}

// MARK: - 心情溫度計時間範圍

enum MoodTimePeriod: String, CaseIterable, Hashable {
    case day, week, month

    var title: String {
        switch self {
        case .day:   return "日"
        case .week:  return "週"
        case .month: return "月"
        }
    }

    var chartTitle: String {
        switch self {
        case .day:   return "今日心情溫度計"
        case .week:  return "近 7 天每小時平均心情"
        case .month: return "近 30 天每小時平均心情"
        }
    }
}
