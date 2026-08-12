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
        case .basic:       return String(localized: "基本")
        case .moodMental:  return String(localized: "情緒與心理狀態")
        case .moodChange:  return String(localized: "情緒變化")
        case .anxiety:     return String(localized: "是否出現焦慮")
        case .impulse:     return String(localized: "衝動行為")
        case .sleep:       return String(localized: "睡眠狀況")
        case .studyFocus:  return String(localized: "課業與專注力")
        case .body:        return String(localized: "身體狀況")
        case .observation: return String(localized: "特別觀察")
        case .custom:      return String(localized: "自訂")
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

    /// 內建模組的預設問題（與每日紀錄硬編碼畫面同步）
    var defaultQuestions: [QuestionDefinition] {
        switch self {
        case .basic:
            return [
                QuestionDefinition(type: .singleSelect, title: String(localized: "天氣"), options: [String(localized: "晴"), String(localized: "雨")]),
                QuestionDefinition(type: .timePicker, title: String(localized: "起床時間")),
                QuestionDefinition(type: .timePicker, title: String(localized: "昨晚上床時間")),
            ]
        case .moodMental:
            return [
                QuestionDefinition(type: .slider, title: String(localized: "整體情緒分數"), rangeMin: 1, rangeMax: 10),
                QuestionDefinition(type: .slider, title: String(localized: "焦慮程度"), rangeMin: 1, rangeMax: 10),
            ]
        case .moodChange:
            return [
                QuestionDefinition(type: .singleSelect, title: String(localized: "狀態（單選）"), options: [String(localized: "穩定"), String(localized: "變高")]),
                QuestionDefinition(type: .multiSelect, title: String(localized: "原因（可複選）"), options: [String(localized: "焦慮"), String(localized: "突發狀況"), String(localized: "其他")]),
                QuestionDefinition(type: .freeText, title: String(localized: "持續時間")),
                QuestionDefinition(type: .multiSelect, title: String(localized: "用什麼方式穩定下來（可複選）"), options: [String(localized: "深呼吸"), String(localized: "聽音樂"), String(localized: "活動身體"), String(localized: "其他")]),
            ]
        case .anxiety:
            return [
                QuestionDefinition(type: .singleSelect, title: String(localized: "程度（單選）"), options: [String(localized: "無"), String(localized: "輕微"), String(localized: "中等"), String(localized: "嚴重")]),
                QuestionDefinition(type: .multiSelect, title: String(localized: "原因（可複選）"), options: [String(localized: "環境"), String(localized: "課業"), String(localized: "突發狀況"), String(localized: "其他")]),
                QuestionDefinition(type: .freeText, title: String(localized: "持續時間")),
                QuestionDefinition(type: .multiSelect, title: String(localized: "焦慮表現（可複選）"), options: [String(localized: "心跳快"), String(localized: "顫抖"), String(localized: "冒汗"), String(localized: "其他")]),
                QuestionDefinition(type: .multiSelect, title: String(localized: "用什麼方式穩定下來（可複選）"), options: [String(localized: "深呼吸"), String(localized: "聽音樂"), String(localized: "活動身體"), String(localized: "其他")]),
            ]
        case .impulse:
            return [
                QuestionDefinition(type: .multiSelect, title: String(localized: "程度（可複選）"), options: [String(localized: "輕微"), String(localized: "中等"), String(localized: "嚴重")]),
                QuestionDefinition(type: .multiSelect, title: String(localized: "衝動行為（可複選）"), options: [String(localized: "上網"), String(localized: "做喜歡的事"), String(localized: "衝動購物"), String(localized: "熬夜"), String(localized: "其他")]),
            ]
        case .sleep:
            return [
                QuestionDefinition(type: .singleSelect, title: String(localized: "入睡所需時間（單選）"), options: [String(localized: "30分鐘以內"), String(localized: "30分鐘～1小時內"), String(localized: "超過1小時以上")]),
                QuestionDefinition(type: .numberInput, title: String(localized: "睡眠時長（小時）"), rangeMin: 0, rangeMax: 16),
                QuestionDefinition(type: .singleSelect, title: String(localized: "睡眠品質（單選）"), options: [String(localized: "不錯（起床之後很有動力做事，情緒穩定，不太感到疲勞）"), String(localized: "普通（起床之後可以做事）"), String(localized: "不好（難以起床做事或容易感到疲勞）")]),
            ]
        case .studyFocus:
            return [
                QuestionDefinition(type: .singleSelect, title: String(localized: "是否完成今日待辦事項（單選）"), options: [String(localized: "是，全部完成"), String(localized: "否，全部沒完成"), String(localized: "部分完成")]),
                QuestionDefinition(type: .singleSelect, title: String(localized: "今日專注度（單選）"), options: [String(localized: "不錯（可以順利做完該做的事，並有餘力做想做的事）"), String(localized: "普通（可以順利做完該做的事）"), String(localized: "容易分心（勉強做完該做的事）"), String(localized: "無法專注")]),
                QuestionDefinition(type: .multiSelect, title: String(localized: "可能原因（可複選）"), options: [String(localized: "疲勞"), String(localized: "一直想想做的事"), String(localized: "其他")]),
                QuestionDefinition(type: .singleSelect, title: String(localized: "今日未完成事項（單選）"), options: [String(localized: "無"), String(localized: "有")]),
                QuestionDefinition(type: .multiSelect, title: String(localized: "遇到的困難（可複選）"), options: [String(localized: "時間不夠"), String(localized: "忘記作業內容"), String(localized: "不會做"), String(localized: "無法專注"), String(localized: "疲勞"), String(localized: "做想做的事"), String(localized: "其他")]),
            ]
        case .body:
            return [
                QuestionDefinition(type: .slider, title: String(localized: "今日疲勞程度"), rangeMin: 1, rangeMax: 10),
                QuestionDefinition(type: .multiSelect, title: String(localized: "不舒服的地方（可複選）"), options: [String(localized: "頭痛"), String(localized: "肚子痛"), String(localized: "肌肉緊繃"), String(localized: "經痛"), String(localized: "眼睛乾澀")]),
                QuestionDefinition(type: .singleSelect, title: String(localized: "是否注意到身體的狀況（單選）"), options: [String(localized: "有，很快就注意到"), String(localized: "有，經過一段時間才注意到"), String(localized: "沒有")]),
                QuestionDefinition(type: .multiSelect, title: String(localized: "因為（可複選）"), options: [String(localized: "手受傷"), String(localized: "肢體僵硬"), String(localized: "無法開口"), String(localized: "疲勞"), String(localized: "拔頭髮"), String(localized: "其他")]),
            ]
        case .observation:
            return [
                QuestionDefinition(type: .freeText, title: String(localized: "特別觀察到的事情")),
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
        case .slider:            return String(localized: "滑桿 (1-10)")
        case .singleSelect:      return String(localized: "單選")
        case .multiSelect:       return String(localized: "多選")
        case .freeText:          return String(localized: "自由文字")
        case .timePicker:        return String(localized: "時間選擇")
        case .numberInput:       return String(localized: "數字輸入")
        case .photo:             return String(localized: "照片")
        case .nestedMultiSelect: return String(localized: "巢狀多選")
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

    /// 條件顯示的選項列表（儲存使用者編輯後的完整列表）
    var triggerOptionLabels: [String]?

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
    var otherText: String?               // 選「其他」時的自由填寫
    var nestedOtherText: [String: String]? // 巢狀多選各分組的「其他」填寫
}

// MARK: - 動態選項包裝（讓 String 可搭配 CheckboxSingleSelectList / CheckboxMultiSelectList）

struct DynamicOption: Identifiable, Hashable, RawRepresentable {
    let rawValue: String
    var id: String { rawValue }

    init(rawValue: String) {
        self.rawValue = rawValue
    }
}
