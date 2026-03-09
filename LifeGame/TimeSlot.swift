import SwiftUI

enum TimeSlot: String, CaseIterable, Identifiable, Codable {
    case morning
    case afternoon
    case evening
    case night
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .morning: return "sunrise"
        case .afternoon: return "sun.max"
        case .evening: return "sunset"
        case .night: return "moon.stars"
        }
    }
    
    var displayName: String {
        switch self {
        case .morning: return "早上"
        case .afternoon: return "下午"
        case .evening: return "晚上"
        case .night: return "深夜"
        }
    }
}
