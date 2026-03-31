import Foundation

// MARK: - DaySlot
enum DaySlot: String, CaseIterable, Identifiable, Codable {
    case morning, afternoon, evening, night
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .morning: return "早上"
        case .afternoon: return "下午"
        case .evening: return "晚上"
        case .night: return "深夜"
        }
    }
    
    var icon: String {
        switch self {
        case .morning: return "sunrise"
        case .afternoon: return "sun.max"
        case .evening: return "sunset"
        case .night: return "moon.stars"
        }
    }
}

// MARK: - Weekday
enum Weekday: Int, CaseIterable, Codable, Identifiable, Hashable {
    case sunday = 1, monday = 2, tuesday = 3, wednesday = 4,
         thursday = 5, friday = 6, saturday = 7

    var id: Int { rawValue }

    var shortTitle: String {
        switch self {
        case .sunday: return "日"
        case .monday: return "一"
        case .tuesday: return "二"
        case .wednesday: return "三"
        case .thursday: return "四"
        case .friday: return "五"
        case .saturday: return "六"
        }
    }

    var title: String {
        switch self {
        case .sunday: return "週日"
        case .monday: return "週一"
        case .tuesday: return "週二"
        case .wednesday: return "週三"
        case .thursday: return "週四"
        case .friday: return "週五"
        case .saturday: return "週六"
        }
    }

    static var today: Weekday {
        Weekday(rawValue: Calendar.current.component(.weekday, from: Date())) ?? .monday
    }
}

// MARK: - RingItem
struct RingItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var slot: DaySlot
    var startMinute: Int
    var endMinute: Int
    var title: String
    var icon: String
    var colorHex: String
    var hpCost: Int
    var fpCost: Int
    var isFromSchedule: Bool = false
}

// MARK: - WeeklySchedule
struct WeeklySchedule: Codable {
    var scheduleByDay: [String: [RingItem]] = [:]

    func items(for weekday: Weekday) -> [RingItem] {
        scheduleByDay[String(weekday.rawValue)] ?? []
    }

    mutating func setItems(_ items: [RingItem], for weekday: Weekday) {
        scheduleByDay[String(weekday.rawValue)] = items
    }

    init() {
        scheduleByDay = [:]
    }
}

// MARK: - TomorrowRingPlan
struct TomorrowRingPlan: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var baseHP: Int = 100
    var baseFP: Int = 100
    var items: [RingItem]
    
    var remainingHP: Int {
        max(0, baseHP - items.reduce(0) { $0 + $1.hpCost })
    }
    
    var remainingFP: Int {
        max(0, baseFP - items.reduce(0) { $0 + $1.fpCost })
    }
}

// MARK: - 時段圖示選單

struct RingIconGroup: Identifiable {
    let id: String
    let title: String
    let icons: [(name: String, label: String)]
}

enum RingIcons {
    static let groups: [RingIconGroup] = [
        RingIconGroup(id: "daily", title: "日常", icons: [
            ("clock", "時鐘"), ("alarm", "鬧鐘"), ("bed.double", "睡覺"),
            ("moon.zzz", "睡眠"), ("cup.and.saucer", "休息"),
            ("fork.knife", "用餐"), ("mug", "飲料"),
            ("house", "在家"), ("car", "交通"), ("bus", "公車"),
            ("tram", "捷運"), ("figure.walk", "走路"),
        ]),
        RingIconGroup(id: "study", title: "學習", icons: [
            ("book", "書本"), ("book.closed", "閱讀"),
            ("pencil.and.ruler", "作業"), ("graduationcap", "上課"),
            ("desktopcomputer", "電腦"), ("laptopcomputer", "筆電"),
            ("brain.head.profile", "思考"), ("lightbulb", "靈感"),
            ("text.book.closed", "教科書"), ("pencil", "寫字"),
        ]),
        RingIconGroup(id: "exercise", title: "運動", icons: [
            ("figure.run", "跑步"), ("figure.yoga", "瑜珈"),
            ("figure.basketball", "籃球"), ("figure.swimming", "游泳"),
            ("figure.badminton", "羽球"), ("figure.archery", "弓道"),
            ("bicycle", "騎車"), ("dumbbell", "重訓"),
            ("figure.martial.arts", "武術"), ("figure.dance", "舞蹈"),
        ]),
        RingIconGroup(id: "life", title: "生活", icons: [
            ("cart", "購物"), ("bag", "外出"),
            ("paintbrush", "創作"), ("music.note", "音樂"),
            ("gamecontroller", "遊戲"), ("tv", "看劇"),
            ("camera", "拍照"), ("heart", "約會"),
            ("person.2", "社交"), ("phone", "通話"),
            ("bubble.left", "聊天"), ("hand.raised", "志工"),
        ]),
        RingIconGroup(id: "work", title: "工作", icons: [
            ("briefcase", "工作"), ("doc.text", "文件"),
            ("calendar", "會議"), ("envelope", "信件"),
            ("chart.bar", "報表"), ("wrench", "修理"),
            ("scissors", "手作"), ("printer", "列印"),
        ]),
    ]

    /// 所有圖示的扁平列表
    static var all: [(name: String, label: String)] {
        groups.flatMap(\.icons)
    }
}

// MARK: - Sample (for preview / development)
extension TomorrowRingPlan {
    static var sample: TomorrowRingPlan {
        TomorrowRingPlan(date: Date(), items: [])
    }
}
