import Foundation

enum CalendarScope: String, CaseIterable, Identifiable {
    case month
    case week
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .month: return String(localized: "月")
        case .week:  return String(localized: "週")
        }
    }
}
