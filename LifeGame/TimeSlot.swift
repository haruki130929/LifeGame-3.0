import SwiftUI

enum TimeSlot: String, CaseIterable, Identifiable, Codable {
    case beforeLeave
    case morning
    case earlyAfternoon
    case beforeEnd
    case bedtime

    var id: String { rawValue }

    // MARK: - Icon

    var systemImage: String {
        switch self {
        case .beforeLeave:    return "door.left.hand.open"
        case .morning:        return "sunrise"
        case .earlyAfternoon: return "sun.max"
        case .beforeEnd:      return "sunset"
        case .bedtime:        return "moon.stars"
        }
    }

    // MARK: - 角色預設名稱

    func defaultName(for role: UserRole) -> String {
        switch self {
        case .beforeLeave:
            return role == .student ? "出門前" : "上班前"
        case .morning:
            return "上午"
        case .earlyAfternoon:
            return "下午三點前"
        case .beforeEnd:
            return role == .student ? "下課前" : "下班前"
        case .bedtime:
            return "睡前"
        }
    }

    // MARK: - 靜態預設名稱（不依賴角色，供 fallback 使用）

    var displayName: String {
        defaultName(for: .student)
    }
}
