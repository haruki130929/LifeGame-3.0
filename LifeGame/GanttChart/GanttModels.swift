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
}

// MARK: - GanttItem

struct GanttItem: Identifiable {
    let id: UUID
    let title: String
    let start: Date
    let end: Date
    let colorHex: String
    let source: GanttSource
    let isDone: Bool
    /// 緩衝區的結束時間（緩衝顯示在 end 到 bufferEnd 之間）
    var bufferEnd: Date?
}

// MARK: - GanttMilestone

struct GanttMilestone: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var colorHex: String = "FF6B6B"
}
