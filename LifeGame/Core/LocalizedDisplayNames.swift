// File: Core/LocalizedDisplayNames.swift
//
// 這些 enum 的 rawValue 同時是「寫進使用者資料的識別碼」與「畫面上顯示的文字」。
// rawValue 一旦翻譯，使用者既有的紀錄就會解不回來，因此 rawValue 一律維持原樣，
// 另外用 displayName 提供可在地化的顯示文字。畫面上請一律改用 displayName。
//
// 新增 case 時記得同步補上這裡，否則會編譯失敗（switch 需窮舉）。

import Foundation

/// 可在畫面上顯示、且顯示文字需要在地化的型別。
protocol LocalizedDisplayable {
    var displayName: String { get }
}

// MARK: - IconCategory
extension IconCategory: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .medical: return String(localized: "醫療")
        case .money: return String(localized: "證件金錢")
        case .stationery: return String(localized: "文具")
        case .tech: return "3C"   // 各語言通用，不需翻譯
        case .daily: return String(localized: "生活")
        }
    }
}

// MARK: - RecurringFrequency
extension RecurringFrequency: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .none: return String(localized: "不重複")
        case .daily: return String(localized: "每天")
        case .weekly: return String(localized: "每週")
        case .biweekly: return String(localized: "每兩週")
        case .monthly: return String(localized: "每月")
        }
    }
}

// MARK: - CalendarImportRange
extension CalendarImportRange: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .next3M: return String(localized: "未來 3 個月")
        case .next1Y: return String(localized: "未來 1 年")
        case .past3MNext1Y: return String(localized: "過去 3 個月 ～ 未來 1 年")
        case .past1YNext1Y: return String(localized: "過去 1 年 ～ 未來 1 年")
        }
    }
}

// MARK: - CardSize — Codable：rawValue 已寫入使用者資料，切勿更動
extension CardSize: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .small: return String(localized: "小")
        case .medium: return String(localized: "中")
        case .large: return String(localized: "大")
        }
    }
}

// MARK: - ChartRange
extension ChartRange: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .week: return String(localized: "1 週")
        case .twoWeeks: return String(localized: "2 週")
        case .month: return String(localized: "1 月")
        case .threeMonths: return String(localized: "3 月")
        case .all: return String(localized: "全部")
        }
    }
}

// MARK: - DailyLogExportSheet.ExportFormat
extension DailyLogExportSheet.ExportFormat: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .pdf: return "PDF"   // 各語言通用，不需翻譯
        case .text: return String(localized: "文字檔")
        }
    }
}

// MARK: - Weather — Codable：rawValue 已寫入使用者資料，切勿更動
extension Weather: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .sunny: return String(localized: "晴")
        case .rainy: return String(localized: "雨")
        }
    }
}

// MARK: - MoodChangeType — Codable：rawValue 已寫入使用者資料，切勿更動
extension MoodChangeType: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .stable: return String(localized: "穩定")
        case .higher: return String(localized: "變高")
        }
    }
}

// MARK: - MoodChangeReason — Codable：rawValue 已寫入使用者資料，切勿更動
extension MoodChangeReason: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .anxiety: return String(localized: "焦慮")
        case .unexpected: return String(localized: "突發狀況")
        case .other: return String(localized: "其他")
        }
    }
}

// MARK: - StabilizeMethod — Codable：rawValue 已寫入使用者資料，切勿更動
extension StabilizeMethod: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .breathing: return String(localized: "深呼吸")
        case .music: return String(localized: "聽音樂")
        case .exercise: return String(localized: "活動身體")
        case .other: return String(localized: "其他")
        }
    }
}

// MARK: - AnxietyLevel — Codable：rawValue 已寫入使用者資料，切勿更動
extension AnxietyLevel: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .none: return String(localized: "無")
        case .mild: return String(localized: "輕微")
        case .medium: return String(localized: "中等")
        case .severe: return String(localized: "嚴重")
        }
    }
}

// MARK: - AnxietyReason — Codable：rawValue 已寫入使用者資料，切勿更動
extension AnxietyReason: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .environment: return String(localized: "環境")
        case .study: return String(localized: "課業")
        case .unexpected: return String(localized: "突發狀況")
        case .other: return String(localized: "其他")
        }
    }
}

// MARK: - AnxietySymptom — Codable：rawValue 已寫入使用者資料，切勿更動
extension AnxietySymptom: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .fastHeartbeat: return String(localized: "心跳快")
        case .tremble: return String(localized: "顫抖")
        case .sweat: return String(localized: "冒汗")
        case .other: return String(localized: "其他")
        }
    }
}

// MARK: - ImpulseLevel — Codable：rawValue 已寫入使用者資料，切勿更動
extension ImpulseLevel: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .none: return String(localized: "無")
        case .mild: return String(localized: "輕微")
        case .medium: return String(localized: "中等")
        case .severe: return String(localized: "嚴重")
        case .other: return String(localized: "其他")
        }
    }
}

// MARK: - ImpulseType — Codable：rawValue 已寫入使用者資料，切勿更動
extension ImpulseType: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .browsing: return String(localized: "上網")
        case .favorite: return String(localized: "做喜歡的事")
        case .impulseShopping: return String(localized: "衝動購物")
        case .stayingUp: return String(localized: "熬夜")
        case .other: return String(localized: "其他")
        }
    }
}

// MARK: - ImpulseSeverity — Codable：rawValue 已寫入使用者資料，切勿更動
extension ImpulseSeverity: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .mild: return String(localized: "輕微")
        case .medium: return String(localized: "中等")
        case .severe: return String(localized: "嚴重")
        }
    }
}

// MARK: - SleepLatency — Codable：rawValue 已寫入使用者資料，切勿更動
extension SleepLatency: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .under30: return String(localized: "30分鐘以內")
        case .under60: return String(localized: "30分鐘～1小時內")
        case .over60: return String(localized: "超過1小時以上")
        }
    }
}

// MARK: - SleepQuality — Codable：rawValue 已寫入使用者資料，切勿更動
extension SleepQuality: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .good: return String(localized: "不錯（起床之後很有動力做事，情緒穩定，不太感到疲勞）")
        case .normal: return String(localized: "普通（起床之後可以做事）")
        case .bad: return String(localized: "不好（難以起床做事或容易感到疲勞）")
        }
    }
}

// MARK: - TodoCompletion — Codable：rawValue 已寫入使用者資料，切勿更動
extension TodoCompletion: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .allDone: return String(localized: "是，全部完成")
        case .noneDone: return String(localized: "否，全部沒完成")
        case .partial: return String(localized: "部分完成")
        }
    }
}

// MARK: - FocusQuality — Codable：rawValue 已寫入使用者資料，切勿更動
extension FocusQuality: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .good: return String(localized: "不錯（可以順利做完該做的事，並有餘力做想做的事）")
        case .normal: return String(localized: "普通（可以順利做完該做的事）")
        case .distractible: return String(localized: "容易分心（勉強做完該做的事）")
        case .cannotFocus: return String(localized: "無法專注")
        }
    }
}

// MARK: - CannotFocusReason — Codable：rawValue 已寫入使用者資料，切勿更動
extension CannotFocusReason: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .tired: return String(localized: "疲勞")
        case .keepThinking: return String(localized: "一直想想做的事")
        case .other: return String(localized: "其他")
        }
    }
}

// MARK: - DifficultyReason — Codable：rawValue 已寫入使用者資料，切勿更動
extension DifficultyReason: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .notEnoughTime: return String(localized: "時間不夠")
        case .forgotHomework: return String(localized: "忘記作業內容")
        case .dontKnowHow: return String(localized: "不會做")
        case .cannotFocus: return String(localized: "無法專注")
        case .tired: return String(localized: "疲勞")
        case .doWantToDo: return String(localized: "做想做的事")
        case .other: return String(localized: "其他")
        }
    }
}

// MARK: - PainArea — Codable：rawValue 已寫入使用者資料，切勿更動
extension PainArea: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .headache: return String(localized: "頭痛")
        case .stomachache: return String(localized: "肚子痛")
        case .muscleTension: return String(localized: "肌肉緊繃")
        case .menstrualPain: return String(localized: "經痛")
        case .dryEyes: return String(localized: "眼睛乾澀")
        }
    }
}

// MARK: - BodyNoticeTiming — Codable：rawValue 已寫入使用者資料，切勿更動
extension BodyNoticeTiming: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .quick: return String(localized: "有，很快就注意到")
        case .late: return String(localized: "有，經過一段時間才注意到")
        case .none: return String(localized: "沒有")
        }
    }
}

// MARK: - BodyLateReason — Codable：rawValue 已寫入使用者資料，切勿更動
extension BodyLateReason: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .selfHarm: return String(localized: "手受傷")
        case .stiff: return String(localized: "肢體僵硬")
        case .cannotSpeak: return String(localized: "無法開口")
        case .tired: return String(localized: "疲勞")
        case .hairPulling: return String(localized: "拔頭髮")
        case .other: return String(localized: "其他")
        }
    }
}

// MARK: - MonthlyScoreChartView.Period
extension MonthlyScoreChartView.Period: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .week: return String(localized: "週")
        case .month: return String(localized: "月")
        }
    }
}

// MARK: - EquipSlot — Codable：rawValue 已寫入使用者資料，切勿更動
extension EquipSlot: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .head: return String(localized: "頭飾")
        case .hand: return String(localized: "手飾")
        case .action: return String(localized: "行動物品")
        case .care: return String(localized: "保養品")
        case .comfort: return String(localized: "隨身小物")
        }
    }
}

// MARK: - EquipEffect.Kind
extension EquipEffect.Kind: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .mpMax: return String(localized: "增加 MP 上限")
        case .weight: return String(localized: "增加重量")
        }
    }
}

// MARK: - GanttTimeScale
extension GanttTimeScale: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .day: return String(localized: "日")
        case .week: return String(localized: "週")
        case .month: return String(localized: "月")
        }
    }
}

// MARK: - LGCategory
extension LGCategory: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .tools: return String(localized: "工具功能")
        case .roles: return String(localized: "角色設定")
        case .growth: return String(localized: "自我成長")
        case .help: return String(localized: "困難幫助")
        case .diary: return String(localized: "日記")
        }
    }
}

// MARK: - SidebarCategory
extension SidebarCategory: LocalizedDisplayable {
    var displayName: String {
        switch self {
        case .periods: return String(localized: "時段")
        case .tools: return String(localized: "工具功能")
        case .roles: return String(localized: "角色設定")
        case .growth: return String(localized: "自我成長")
        case .help: return String(localized: "困難幫助")
        }
    }
}

// MARK: - DynamicOption
// 包的是使用者自己輸入的選項文字，屬於使用者資料而非 App 文案，不可在地化，原樣顯示。
extension DynamicOption: LocalizedDisplayable {
    var displayName: String { rawValue }
}

// MARK: - SleepQuality 簡短形式
// rawValue 是「不錯（起床之後很有動力做事…）」這種長句，摘要與匯出只想顯示前面的評語。
// 原本用 components(separatedBy: "（") 去截，翻成英文/日文後就截不到了，改用明確的短版文案。
extension SleepQuality {
    var shortDisplayName: String {
        switch self {
        case .good: return String(localized: "不錯")
        case .normal: return String(localized: "普通")
        case .bad: return String(localized: "不好")
        }
    }
}
