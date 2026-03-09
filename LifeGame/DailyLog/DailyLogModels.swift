import Foundation

// MARK: - 基本選項

enum Weather: String, CaseIterable, Codable, Identifiable {
    case sunny = "晴"
    case rainy = "雨"
    var id: String { rawValue }
}

// MARK: - 可忘記紀錄的時間（起床時間用）

enum OptionalLogTime: Codable, Equatable {
    case unknown
    case time(Date)
    
    var isUnknown: Bool {
        if case .unknown = self { return true }
        return false
    }
    
    var dateValue: Date? {
        if case .time(let d) = self { return d }
        return nil
    }
}

// MARK: - 情緒與心理狀態

enum MoodChangeType: String, CaseIterable, Codable, Identifiable {
    case stable = "穩定"
    case higher = "變高"
    var id: String { rawValue }
}

enum MoodChangeReason: String, CaseIterable, Codable, Identifiable {
    case anxiety = "焦慮"
    case chat = "聊天"
    case favorite = "做喜歡的事"
    case other = "其他"
    var id: String { rawValue }
}

enum StabilizeMethod: String, CaseIterable, Codable, Identifiable {
    case selfHarm = "手受傷"
    case weightedBlanket = "壓力毯"
    case plushBracelet = "毛絨手環"
    case hairPulling = "拔頭髮"
    case other = "其他"
    var id: String { rawValue }
}

enum AnxietyLevel: String, CaseIterable, Codable, Identifiable {
    case none = "無"
    case mild = "輕微"
    case medium = "中等"
    case severe = "嚴重"
    var id: String { rawValue }
}

enum AnxietyReason: String, CaseIterable, Codable, Identifiable {
    case sound = "聲音"
    case crowd = "人多"
    case spotlight = "成為焦點"
    case other = "其他"
    var id: String { rawValue }
}

enum AnxietySymptom: String, CaseIterable, Codable, Identifiable {
    case cannotSpeak = "無法開口"
    case stiff = "肢體僵硬"
    case fastHeartbeat = "心跳快"
    case tremble = "顫抖"
    case other = "其他"
    var id: String { rawValue }
}

// MARK: - 衝動行為

enum ImpulseLevel: String, CaseIterable, Codable, Identifiable {
    case none = "無"
    case mild = "輕微"
    case medium = "中等"
    case severe = "嚴重"
    case other = "其他"
    var id: String { rawValue }
}

enum ImpulseType: String, CaseIterable, Codable, Identifiable {
    case selfHarm = "手受傷"
    case hairPulling = "拔頭髮"
    case impulseShopping = "衝動購物"
    case stayingUp = "熬夜"
    case other = "其他"
    var id: String { rawValue }
}

enum ImpulseSeverity: String, CaseIterable, Codable, Identifiable, Hashable {
    case mild = "輕微"
    case medium = "中等"
    case severe = "嚴重"
    var id: String { rawValue }
}

// MARK: - 睡眠

enum SleepLatency: String, CaseIterable, Codable, Identifiable {
    case under30 = "30分鐘以內"
    case under60 = "30分鐘～1小時內"
    case over60 = "超過1小時以上"
    var id: String { rawValue }
}

enum SleepQuality: String, CaseIterable, Codable, Identifiable {
    case good = "不錯（起床之後很有動力做事，情緒穩定，不太感到疲勞）"
    case normal = "普通（起床之後可以做事）"
    case bad = "不好（難以起床做事或容易感到疲勞）"
    var id: String { rawValue }
}

// MARK: - 課業與專注

enum TodoCompletion: String, CaseIterable, Codable, Identifiable {
    case allDone = "是，全部完成"
    case noneDone = "否，全部沒完成"
    case partial = "部分完成"
    var id: String { rawValue }
}

enum FocusQuality: String, CaseIterable, Codable, Identifiable {
    case good = "不錯（可以順利做完該做的事，並有餘力做想做的事）"
    case normal = "普通（可以順利做完該做的事）"
    case distractible = "容易分心（勉強做完該做的事）"
    case cannotFocus = "無法專注"
    var id: String { rawValue }
}

enum CannotFocusReason: String, CaseIterable, Codable, Identifiable {
    case tired = "疲勞"
    case keepThinking = "一直想想做的事"
    case other = "其他"
    var id: String { rawValue }
}

enum DifficultyReason: String, CaseIterable, Codable, Identifiable {
    case notEnoughTime = "時間不夠"
    case forgotHomework = "忘記作業內容"
    case dontKnowHow = "不會做"
    case cannotFocus = "無法專注"
    case tired = "疲勞"
    case doWantToDo = "做想做的事"
    case other = "其他"
    var id: String { rawValue }
}

// MARK: - 身體狀況

enum PainArea: String, CaseIterable, Codable, Identifiable {
    case headache = "頭痛"
    case rightShoulderBlade = "右肩胛骨內側"
    case rightElbow = "右手肘"
    case rightWrist = "右手腕"
    var id: String { rawValue }
}

enum BodyNoticeTiming: String, CaseIterable, Codable, Identifiable {
    case quick = "有，很快就注意到"
    case late = "有，經過一段時間才注意到"
    case none = "沒有"
    var id: String { rawValue }
}

enum BodyLateReason: String, CaseIterable, Codable, Identifiable {
    case selfHarm = "手受傷"
    case stiff = "肢體僵硬"
    case cannotSpeak = "無法開口"
    case tired = "疲勞"
    case hairPulling = "拔頭髮"
    case other = "其他"
    var id: String { rawValue }
}

// MARK: - 備註照片

struct DailyLogPhoto: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var imageData: Data
    var caption: String = ""
}

// MARK: - 主 Model

struct DailyLogEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    
    // 基本
    var date: Date = .now
    var weather: Weather = .sunny
    
    // 起床（可忘記）＋ 上床（必填但用 30 分鐘刻度）
    var wakeTime: OptionalLogTime = .time(.now)
    var bedTime: OptionalLogTime = .time(.now)
    
    // 情緒與心理狀態（滑動桿 1~10）
    var overallMoodScore: Int = 5
    var anxietyScore: Int = 5
    
    // 情緒變化
    var moodChangeType: MoodChangeType = .stable
    var moodChangeReasons: Set<MoodChangeReason> = []
    var moodChangeOtherText: String = ""
    var moodChangeDurationText: String = ""
    var stabilizeMethodsForMoodChange: Set<StabilizeMethod> = []
    var stabilizeOtherTextForMoodChange: String = ""
    
    // 是否出現焦慮
    var anxietyLevel: AnxietyLevel = .none
    var anxietyReasons: Set<AnxietyReason> = []
    var anxietyOtherText: String = ""
    var anxietyDurationText: String = ""
    var anxietySymptoms: Set<AnxietySymptom> = []
    var anxietySymptomOtherText: String = ""
    var stabilizeMethodsForAnxiety: Set<StabilizeMethod> = []
    var stabilizeOtherTextForAnxiety: String = ""
    
    // 衝動行為（可同時勾輕微/中等/嚴重，每個程度各自一組選項）
    var impulseSeverities: Set<ImpulseSeverity> = []
    var impulseTypesBySeverity: [ImpulseSeverity: Set<ImpulseType>] = [:]
    var impulseOtherTextBySeverity: [ImpulseSeverity: String] = [:]
    
    // 睡眠
    var sleepLatency: SleepLatency = .under30
    var sleepHours: OptionalLogDouble = .value(7.0)   // 0.5 單位
    var sleepQuality: SleepQuality = .normal
    
    // 課業與專注力
    var todoCompletion: TodoCompletion = .allDone
    var todoPartialDone: Int = 0
    var todoPartialTotal: Int = 0
    
    var focusQuality: FocusQuality = .normal
    var cannotFocusReasons: Set<CannotFocusReason> = []
    var cannotFocusOtherText: String = ""
    
    var unfinished: Bool = false
    var unfinishedCount: Int = 0
    var unfinishedTotal: Int = 0
    var difficultyReasons: Set<DifficultyReason> = []
    var difficultyOtherText: String = ""
    
    // 身體狀況
    var fatigueScore: Int = 5   // 改成表單 Slider
    var painAreas: Set<PainArea> = []
    var painScoreByArea: [PainArea: Int] = [:]
    
    var bodyNoticeTiming: BodyNoticeTiming = .quick
    var bodyLateReasons: Set<BodyLateReason> = []
    var bodyLateOtherText: String = ""
    
    // 特別觀察（文字 + 多張照片）
    var specialObservation: String = ""
    var photos: [DailyLogPhoto] = []
}

enum OptionalLogDouble: Codable, Equatable {
    case unknown
    case value(Double)
    
    var isUnknown: Bool {
        if case .unknown = self { return true }
        return false
    }
    
    var doubleValue: Double? {
        if case .value(let v) = self { return v }
        return nil
    }
}
