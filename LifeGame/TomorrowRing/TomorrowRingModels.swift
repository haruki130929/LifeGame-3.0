import Foundation

// MARK: - DaySlot
enum DaySlot: String, CaseIterable, Identifiable, Codable {
    case morning, afternoon, evening, night
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .morning: return String(localized: "早上")
        case .afternoon: return String(localized: "下午")
        case .evening: return String(localized: "晚上")
        case .night: return String(localized: "深夜")
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

// MARK: - 星期名稱快取
/// 取系統的星期名稱，並快取起來，避免每次畫面更新都重建 DateFormatter。
/// 使用者在系統設定換語言後，App 會重啟，這裡也會跟著重新取一次。
final class WeekdaySymbolCache {
    private var localeID = ""
    private var veryShortSymbols: [String] = []
    private var shortSymbols: [String] = []

    private func refreshIfNeeded() {
        let current = Locale.current.identifier
        guard current != localeID || veryShortSymbols.isEmpty else { return }
        let df = DateFormatter()
        df.locale = .current
        localeID = current
        veryShortSymbols = df.veryShortWeekdaySymbols ?? []
        shortSymbols = df.shortWeekdaySymbols ?? []
    }

    /// weekday：1 = 週日 … 7 = 週六
    func veryShort(_ weekday: Int) -> String {
        refreshIfNeeded()
        return veryShortSymbols.indices.contains(weekday - 1) ? veryShortSymbols[weekday - 1] : ""
    }

    func short(_ weekday: Int) -> String {
        refreshIfNeeded()
        return shortSymbols.indices.contains(weekday - 1) ? shortSymbols[weekday - 1] : ""
    }
}

// MARK: - Weekday
enum Weekday: Int, CaseIterable, Codable, Identifiable, Hashable {
    case sunday = 1, monday = 2, tuesday = 3, wednesday = 4,
         thursday = 5, friday = 6, saturday = 7

    var id: Int { rawValue }

    // 星期名稱一律取自系統，不寫死字面值：
    //   zh-Hant → 日／週日、ja → 日／日、en → S／Sun
    // 寫死的話，「日」既是星期日又是甘特圖的「日」刻度，在 String Catalog 裡會共用同一個 key，
    // 翻成英文時必然有一邊是錯的。
    private static let symbolCache = WeekdaySymbolCache()

    var shortTitle: String {
        Self.symbolCache.veryShort(rawValue)
    }

    var title: String {
        Self.symbolCache.short(rawValue)
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
