import Foundation

// MARK: - 日記條目

struct DiaryEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date = .now

    /// 日記內容（自由文字）
    var content: String = ""

    /// 使用者填寫的自訂模組回答
    var answers: [CustomAnswer] = []
}
