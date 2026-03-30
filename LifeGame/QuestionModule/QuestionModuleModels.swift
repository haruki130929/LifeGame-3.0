import Foundation

// MARK: - 模組種類

enum ModuleKind: String, Codable, CaseIterable, Identifiable {
    // 內建區塊（對應現有 DailyLogFormView 的 Section）
    case basic           // 基本
    case moodMental      // 情緒與心理狀態
    case moodChange      // 情緒變化
    case anxiety         // 是否出現焦慮
    case impulse         // 衝動行為
    case sleep           // 睡眠狀況
    case studyFocus      // 課業與專注力
    case body            // 身體狀況
    case observation     // 特別觀察

    // 使用者自訂
    case custom

    var id: String { rawValue }

    /// 內建模組的預設標題
    var defaultTitle: String {
        switch self {
        case .basic:       return "基本"
        case .moodMental:  return "情緒與心理狀態"
        case .moodChange:  return "情緒變化"
        case .anxiety:     return "是否出現焦慮"
        case .impulse:     return "衝動行為"
        case .sleep:       return "睡眠狀況"
        case .studyFocus:  return "課業與專注力"
        case .body:        return "身體狀況"
        case .observation: return "特別觀察"
        case .custom:      return "自訂"
        }
    }

    /// 內建模組的預設圖示
    var defaultIcon: String {
        switch self {
        case .basic:       return "doc.text"
        case .moodMental:  return "brain.head.profile"
        case .moodChange:  return "arrow.up.arrow.down"
        case .anxiety:     return "exclamationmark.triangle"
        case .impulse:     return "bolt"
        case .sleep:       return "moon.zzz"
        case .studyFocus:  return "book"
        case .body:        return "figure.walk"
        case .observation: return "eye"
        case .custom:      return "square.grid.2x2"
        }
    }

    var isBuiltIn: Bool { self != .custom }

    /// 所有內建種類（排除 .custom）
    static var builtInCases: [ModuleKind] {
        allCases.filter { $0.isBuiltIn }
    }

    /// 內建模組的預設問題
    var defaultQuestions: [QuestionDefinition] {
        switch self {
        case .basic:
            return [
                QuestionDefinition(type: .timePicker, title: "起床時間"),
                QuestionDefinition(type: .timePicker, title: "昨晚上床時間"),
                QuestionDefinition(type: .singleSelect, title: "天氣", options: ["晴", "多雲", "陰", "小雨", "大雨", "雷雨", "雪"]),
            ]
        case .moodMental:
            return [
                QuestionDefinition(type: .slider, title: "整體情緒分數", rangeMin: 0, rangeMax: 10),
                QuestionDefinition(type: .slider, title: "焦慮程度", rangeMin: 0, rangeMax: 10),
            ]
        case .moodChange:
            return [
                QuestionDefinition(type: .singleSelect, title: "狀態", options: ["穩定", "略有波動", "明顯波動", "劇烈波動"]),
                QuestionDefinition(type: .multiSelect, title: "原因", options: ["課業壓力", "人際關係", "家庭", "身體不適", "睡眠不足", "其他"]),
                QuestionDefinition(type: .freeText, title: "持續時間"),
                QuestionDefinition(type: .multiSelect, title: "穩定方式", options: ["深呼吸", "散步", "聽音樂", "找人聊", "寫日記", "運動", "其他"]),
            ]
        case .anxiety:
            return [
                QuestionDefinition(type: .singleSelect, title: "程度", options: ["無", "輕微", "中等", "嚴重"]),
                QuestionDefinition(type: .multiSelect, title: "原因", options: ["課業", "考試", "人際", "未來擔憂", "家庭", "其他"]),
                QuestionDefinition(type: .freeText, title: "持續時間"),
                QuestionDefinition(type: .multiSelect, title: "焦慮表現", options: ["心跳加速", "手抖", "胃不舒服", "注意力渙散", "呼吸急促", "其他"]),
                QuestionDefinition(type: .multiSelect, title: "穩定方式", options: ["深呼吸", "轉移注意", "找人聊", "運動", "其他"]),
            ]
        case .impulse:
            return [
                QuestionDefinition(type: .singleSelect, title: "是否有衝動行為", options: ["無", "有"]),
                QuestionDefinition(type: .multiSelect, title: "衝動類型", options: ["言語衝動", "情緒爆發", "衝動消費", "暴飲暴食", "其他"]),
            ]
        case .sleep:
            return [
                QuestionDefinition(type: .singleSelect, title: "入睡所需時間", options: ["少於 15 分鐘", "15-30 分鐘", "30-60 分鐘", "超過 1 小時"]),
                QuestionDefinition(type: .numberInput, title: "睡眠時長（小時）", rangeMin: 0, rangeMax: 16),
                QuestionDefinition(type: .singleSelect, title: "睡眠品質", options: ["很好", "普通", "不太好", "很差"]),
            ]
        case .studyFocus:
            return [
                QuestionDefinition(type: .singleSelect, title: "是否完成今日待辦事項", options: ["全部完成", "部分完成", "沒有完成"]),
                QuestionDefinition(type: .singleSelect, title: "今日專注度", options: ["很好", "普通", "不太好", "很差"]),
                QuestionDefinition(type: .multiSelect, title: "影響專注的原因", options: ["手機", "噪音", "疲勞", "心情", "其他"]),
                QuestionDefinition(type: .singleSelect, title: "有未完成事項嗎", options: ["沒有", "有"]),
                QuestionDefinition(type: .multiSelect, title: "遇到的困難", options: ["不理解內容", "缺乏動力", "時間不夠", "太難", "其他"]),
            ]
        case .body:
            return [
                QuestionDefinition(type: .slider, title: "今日疲勞程度", rangeMin: 0, rangeMax: 10),
                QuestionDefinition(type: .multiSelect, title: "不舒服的地方", options: ["頭", "眼睛", "肩頸", "背", "腰", "胃", "四肢", "無"]),
                QuestionDefinition(type: .singleSelect, title: "是否注意到身體狀況", options: ["有", "沒有"]),
                QuestionDefinition(type: .multiSelect, title: "原因", options: ["運動", "久坐", "壓力", "睡眠不足", "飲食", "其他"]),
            ]
        case .observation:
            return [
                QuestionDefinition(type: .freeText, title: "特別觀察到的事情"),
            ]
        case .custom:
            return []
        }
    }
}

// MARK: - 每日紀錄模組

struct DailyLogModule: Identifiable, Codable, Equatable {
    let id: UUID
    let kind: ModuleKind
    var isEnabled: Bool
    var sortOrder: Int

    // 自訂模組才需要
    var title: String?
    var icon: String?
    var questions: [QuestionDefinition]?

    /// 顯示用標題
    var displayTitle: String {
        title ?? kind.defaultTitle
    }

    /// 顯示用圖示
    var displayIcon: String {
        icon ?? kind.defaultIcon
    }

    /// 顯示用問題列表（自訂優先，否則用內建預設）
    var displayQuestions: [QuestionDefinition] {
        if let q = questions, !q.isEmpty { return q }
        return kind.defaultQuestions
    }

    init(
        id: UUID = UUID(),
        kind: ModuleKind,
        isEnabled: Bool = true,
        sortOrder: Int = 0,
        title: String? = nil,
        icon: String? = nil,
        questions: [QuestionDefinition]? = nil
    ) {
        self.id = id
        self.kind = kind
        self.isEnabled = isEnabled
        self.sortOrder = sortOrder
        self.title = title
        self.icon = icon
        self.questions = questions
    }
}

// MARK: - 問題類型

enum QuestionType: String, Codable, CaseIterable, Identifiable {
    case slider            // 1-10 滑桿
    case singleSelect      // 單選
    case multiSelect       // 多選
    case freeText          // 自由文字
    case timePicker        // 時間選擇（30 分鐘刻度）
    case numberInput       // 數字輸入
    case photo             // 照片
    case nestedMultiSelect // 巢狀多選（如衝動行為：程度 → 類型）

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .slider:            return "滑桿 (1-10)"
        case .singleSelect:      return "單選"
        case .multiSelect:       return "多選"
        case .freeText:          return "自由文字"
        case .timePicker:        return "時間選擇"
        case .numberInput:       return "數字輸入"
        case .photo:             return "照片"
        case .nestedMultiSelect: return "巢狀多選"
        }
    }
}

// MARK: - 問題定義

struct QuestionDefinition: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var type: QuestionType
    var title: String

    /// 單選 / 多選的選項
    var options: [String]?

    /// 滑桿 / 數字的範圍（min, max）
    var rangeMin: Int?
    var rangeMax: Int?

    /// 條件觸發：當父問題的答案符合時才顯示
    var conditionalTrigger: ConditionalTrigger?

    /// 子問題（條件式）
    var subQuestions: [QuestionDefinition]?

    /// 巢狀多選的分組（如 輕微/中等/嚴重 各自有子選項）
    var nestedGroups: [NestedGroup]?
}

// MARK: - 條件觸發

struct ConditionalTrigger: Codable, Equatable {
    var parentQuestionId: UUID
    var triggerValues: [String]
}

// MARK: - 巢狀分組

struct NestedGroup: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var label: String
    var subOptions: [String]
}

// MARK: - 自訂問題的答案

struct CustomAnswer: Codable, Equatable, Identifiable, Sendable {
    var id: UUID { questionId }
    var questionId: UUID

    // 根據問題類型使用不同欄位
    var stringValue: String?
    var intValue: Int?
    var stringArrayValue: [String]?
    var nestedValue: [String: [String]]?  // 巢狀多選: groupLabel -> [selectedOptions]
    var dateValue: Date?
    var photoData: [Data]?
}

// MARK: - 動態選項包裝（讓 String 可搭配 CheckboxSingleSelectList / CheckboxMultiSelectList）

struct DynamicOption: Identifiable, Hashable, RawRepresentable {
    let rawValue: String
    var id: String { rawValue }

    init(rawValue: String) {
        self.rawValue = rawValue
    }
}
