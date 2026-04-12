import Foundation

// MARK: - GanttTimeScale

enum GanttTimeScale: String, CaseIterable {
    case day = "日"
    case week = "週"
    case month = "月"
}

// MARK: - GanttSource

enum GanttSource {
    case calendar
    case todo
    case custom       // 使用者自建的任務
    case parentTask   // 父任務（摘要條）
}

// MARK: - GanttItem (顯示用)

struct GanttItem: Identifiable {
    let id: UUID
    let title: String
    let start: Date
    let end: Date
    let colorHex: String
    let source: GanttSource
    let isDone: Bool
    var bufferEnd: Date?
    var indentLevel: Int = 0   // 0 = 頂層, 1 = 子任務
    var taskRef: GanttTask?    // 對應的原始 task（供編輯用）
}

// MARK: - GanttTask (使用者自建任務，持久化)

struct GanttTask: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var start: Date
    var end: Date
    var colorHex: String = "339AF0"
    var isDone: Bool = false
    var order: Int = 0
    var parentId: UUID? = nil       // nil = 頂層任務
    var isSequential: Bool = false  // true = 做完上一個才能做下一個
}

// MARK: - GanttMilestone

struct GanttMilestone: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var colorHex: String = "FF6B6B"
}
