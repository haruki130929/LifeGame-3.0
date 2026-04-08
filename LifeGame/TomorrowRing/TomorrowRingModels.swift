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

    /// 以凌晨 4 點為日期分界的「今天」星期幾
    static var today: Weekday {
        let cal = Calendar.current
        let now = Date()
        // 4 點前算前一天
        let adjustedDate = cal.date(byAdding: .hour, value: -4, to: now) ?? now
        return Weekday(rawValue: cal.component(.weekday, from: adjustedDate)) ?? .monday
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

// MARK: - Sample (for preview / development)
extension TomorrowRingPlan {
    static var sample: TomorrowRingPlan {
        TomorrowRingPlan(date: Date(), items: [])
    }
}
