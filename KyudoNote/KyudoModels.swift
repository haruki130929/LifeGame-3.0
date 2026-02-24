import SwiftUI

struct KyudoHit: Identifiable, Codable, Equatable {
    let id: UUID
    var x: CGFloat   // -1 ~ 1 (center = 0)
    var y: CGFloat   // -1 ~ 1
    
    init(id: UUID = UUID(), x: CGFloat, y: CGFloat) {
        self.id = id
        self.x = x
        self.y = y
    }
}

struct KyudoNote: Codable, Equatable {
    var date: Date = Date()
    var practiceMenu: String = ""
    var todayGoal: String = ""
    var specialFocus: String = ""
    var coachedPoints: String = ""
    var nextGoal: String = ""
    var todaysStory: String = ""
    var hits: [KyudoHit] = []
    var insightsFromHits: String = ""
}
