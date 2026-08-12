import Foundation

// MARK: - 圖表類型

enum ChartType: String, Codable, CaseIterable, Identifiable {
    case line  = "line"   // 折線圖
    case pie   = "pie"    // 圓餅圖
    case bar   = "bar"    // 長條圖
    case radar = "radar"  // 雷達圖

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .line:  return String(localized: "折線圖")
        case .pie:   return String(localized: "圓餅圖")
        case .bar:   return String(localized: "長條圖")
        case .radar: return String(localized: "雷達圖")
        }
    }

    var systemImage: String {
        switch self {
        case .line:  return "chart.xyaxis.line"
        case .pie:   return "chart.pie"
        case .bar:   return "chart.bar"
        case .radar: return "pentagon"
        }
    }
}

// MARK: - 欄位定義

struct PracticeFieldDefinition: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var question: QuestionDefinition
    /// 使用者手動覆蓋的圖表類型（nil = 自動推斷）
    var chartType: ChartType?

    /// 根據欄位類型自動推斷的預設圖表
    var defaultChartType: ChartType? {
        switch question.type {
        case .slider, .numberInput:
            return .line
        case .singleSelect:
            return .pie
        case .multiSelect:
            return .bar
        default:
            return nil
        }
    }

    /// 實際使用的圖表類型（手動覆蓋 > 自動推斷）
    var effectiveChartType: ChartType? {
        chartType ?? defaultChartType
    }
}

// MARK: - 練習日記

struct PracticeDiary: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var icon: String  // SF Symbol 名稱
    var fields: [PracticeFieldDefinition]
    var createdAt: Date = Date()
}

// MARK: - 練習紀錄

struct PracticeEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var diaryId: UUID
    var date: Date = Date()
    var answers: [CustomAnswer]
}
