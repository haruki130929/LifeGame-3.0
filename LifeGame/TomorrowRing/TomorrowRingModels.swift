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
