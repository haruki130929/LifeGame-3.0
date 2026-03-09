import Foundation

struct KeyTask: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var isDone: Bool = false
}

struct Key3Plan: Identifiable, Codable, Hashable {
    /// 用日期當 id（yyyy-MM-dd）
    var id: String { dateKey }
    
    var dateKey: String
    var purpose: String
    var tasks: [KeyTask]
    var activeTaskID: UUID?
    var updatedAt: Date
}
