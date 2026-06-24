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

    // MARK: - 依目前時間判斷時段

    /// 根據傳入時間（預設為現在）回傳對應的時段，
    /// 供 App 開啟時自動選中目前時間所屬的時段使用。
    static func current(at date: Date = Date(), calendar: Calendar = .current) -> TimeSlot {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 4..<8:   return .beforeLeave    // 出門前/上班前
        case 8..<12:  return .morning        // 上午
        case 12..<15: return .earlyAfternoon // 下午三點前
        case 15..<18: return .beforeEnd      // 下課前/下班前
        default:      return .bedtime        // 睡前（晚上到凌晨）
        }
    }
}
