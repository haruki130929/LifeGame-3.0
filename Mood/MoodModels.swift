import Foundation

struct MoodEntry: Identifiable, Codable, Equatable {
    var id: String              // 用 hourKey 當 id，方便覆寫
    var hourKey: String         // "yyyy-MM-dd HH"（例如 2025-12-27 20）
    var value: Int              // 0...10
}
