import Foundation

struct DailyRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    
    // 善甯可以先用最少欄位，之後再加
    var mood: Int            // 0...10
    var anxiety: Int         // 0...10
    var sleepHours: Double   // 0...24
    var focus: Int           // 0...10
    var note: String
    
    init(
        id: UUID = UUID(),
        date: Date,
        mood: Int = 5,
        anxiety: Int = 5,
        sleepHours: Double = 7,
        focus: Int = 5,
        note: String = ""
    ) {
        self.id = id
        self.date = date
        self.mood = mood
        self.anxiety = anxiety
        self.sleepHours = sleepHours
        self.focus = focus
        self.note = note
    }
}
