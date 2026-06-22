import Foundation

enum TodoQuadrant: Int, CaseIterable, Identifiable, Codable {
    case importantNotUrgent = 0   // 左上（重要不緊急）
    case importantUrgent = 1      // 右上（重要又緊急）
    case notImportantNotUrgent = 2// 左下（不重要不緊急）
    case urgentNotImportant = 3   // 右下（緊急不重要）
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .importantNotUrgent: return "重要不緊急"
        case .importantUrgent: return "重要又緊急"
        case .notImportantNotUrgent: return "不重要不緊急"
        case .urgentNotImportant: return "緊急不重要"
        }
    }

    var fabIcon: String {
        switch self {
        case .importantNotUrgent:    return "star.circle"
        case .importantUrgent:       return "exclamationmark.circle"
        case .notImportantNotUrgent: return "minus.circle"
        case .urgentNotImportant:    return "bolt.circle"
        }
    }
}

struct TodoItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var quadrant: TodoQuadrant
    var isDone: Bool = false
    var createdAt: Date = Date()
    var startDate: Date?
    var dueDate: Date?
    var completedAt: Date?      // 打勾完成的時間（用於「完成一週後自動消失」；舊資料為 nil 不會被自動清除）

    /// 距離截止日期的剩餘天數（負數表示已過期）
    var daysUntilDue: Int? {
        guard let dueDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: dueDate)).day
    }
}
