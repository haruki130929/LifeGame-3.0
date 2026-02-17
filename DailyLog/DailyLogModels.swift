import Foundation

// MARK: - Enums (PDF 選項一模一樣)

enum Weather: String, CaseIterable, Codable, Identifiable {
    case sunny = "晴"
    case rainy = "雨"
    var id: String { rawValue }
}

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

enum ImpulseLevel: String, CaseIterable, Codable, Identifiable {
    case none = "無"
    case mild = "有，輕微"
    case medium = "有，中等"
    case severe = "有，嚴重"
    case other = "有，其他"
    var id: String { rawValue }
}

enum SleepLatency: String, CaseIterable, Codable, Identifiable {
    case under30 = "３０分鐘內"
    case under60 = "３０分鐘～１小時內"
    case over60 = "超過１小時以上"
    var id: String { rawValue }
}

enum SleepQuality: String, CaseIterable, Codable, Identifiable {
    case good = "不錯（起床之後很有動力做事，情緒穩定，不太感到疲勞）"
    case normal = "普通（起床之後可以做事）"
    case bad = "不好（難以起床做事或容易感到疲勞）"
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

enum PainArea: String, CaseIterable, Codable, Identifiable {
    case headache = "頭痛"
    case cheekbone = "右肩頰骨內側"
    case elbow = "右手肘"
    case wrist = "右手腕"
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
    case other = "其他"
    var id: String { rawValue }
}

enum StabilizeMethod: String, CaseIterable, Codable, Identifiable {
    case selfHarm = "手受傷"
    case weightedBlanket = "壓力毯"
    case plushBracelet = "毛絨手環"
    case hairPulling = "拔頭髮"      // ✅ 新增
    case other = "其他"
    var id: String { rawValue }
}

enum ImpulseType: String, CaseIterable, Codable, Identifiable {
    case selfHarm = "手受傷"
    case hairPulling = "拔頭髮"
    case impulseShopping = "衝動購物" // ✅ 新增
    case stayingUp = "熬夜"           // ✅ 新增
    var id: String { rawValue }
}

enum ImpulseSeverity: String, CaseIterable, Codable, Identifiable, Hashable {
    case mild = "輕微"
    case medium = "中等"
    case severe = "嚴重"
    var id: String { rawValue }
}

// MARK: - Model

struct DailyLogEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    
    // 基本
    var date: Date = .now
    var weather: Weather = .sunny
    var wakeTime: Date = .now
    
    // 情緒與心理狀態
    var overallMoodScore: Int = 0
    var anxietyScore: Int = 0
    
    // 情緒變化
    var moodChangeType: MoodChangeType = .stable
    var moodChangeReasons: Set<MoodChangeReason> = []
    var moodChangeOtherText: String = ""
    var moodChangeDurationText: String = ""
    var stabilizeMethodsForMoodChange: Set<StabilizeMethod> = []
    var stabilizeOtherTextForMoodChange: String = ""
    
    // 是否出現焦慮（選一個等級）
    var anxietyLevel: AnxietyLevel = .none
    var anxietyReasons: Set<AnxietyReason> = []
    var anxietyOtherText: String = ""
    var anxietyDurationText: String = ""
    var anxietySymptoms: Set<AnxietySymptom> = []
    var anxietySymptomOtherText: String = ""
    var stabilizeMethodsForAnxiety: Set<StabilizeMethod> = []
    var stabilizeOtherTextForAnxiety: String = ""
    
    // 衝動行為
    var impulseLevel: ImpulseLevel = .none
    var impulseTypes: Set<ImpulseType> = []
    var impulseOtherText: String = ""
    var impulseSeverities: Set<ImpulseSeverity> = []              // ✅ 多選等級
    var impulseTypesBySeverity: [ImpulseSeverity: Set<ImpulseType>] = [:]  // ✅ 每個等級底下的行為
    var impulseOtherTextBySeverity: [ImpulseSeverity: String] = [:]        // ✅ 每個等級的其他文字
    
    // 睡眠狀況
    var bedTime: Date = .now
    var sleepLatency: SleepLatency = .under30
    var sleepHours: Double = 0
    var sleepQuality: SleepQuality = .normal
    
    // 課業與專注力
    var todoCompletion: String = "是，全部完成" // 用文字，保持和 PDF 一致
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
    var fatigueScore: Int = 0
    
    // 疼痛（PDF 是「勾選疼痛的地方＋分數」）
    var painAreas: Set<PainArea> = []
    var painScoreByArea: [PainArea: Int] = [:]
    
    // 身體覺察
    var bodyNoticeTiming: BodyNoticeTiming = .quick
    var bodyLateReasons: Set<BodyLateReason> = []
    var bodyLateOtherText: String = ""
    
    // 特別觀察到的事情
    var specialObservation: String = ""
}
