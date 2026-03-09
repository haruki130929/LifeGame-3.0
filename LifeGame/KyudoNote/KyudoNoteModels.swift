import Foundation
import CoreGraphics

struct ShotPoint: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    /// 0...1 的相對座標（跟畫面大小無關）
    var x: Double
    var y: Double
}

struct KyudoNote: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    
    // 1. 日期
    var date: Date = Date()
    
    // 2. 今日練習菜單
    var practiceMenu: String = ""
    
    // 3. 今日目標
    var todayGoal: String = ""
    
    // 4. 為了達成目標所注意的事情
    var focusPoints: String = ""
    
    // 5. 被指導的地方
    var coachedPoints: String = ""
    
    // 6. 下次的目標
    var nextGoal: String = ""
    
    // 7. 今天發生的事情（跟弓道相關）
    var todayHappened: String = ""
    
    // 8. 射中的地方、中靶率（靶上點擊）
    var shots: [ShotPoint] = []
    /// 中靶判定：離中心 <= hitRadius 則算中
    var hitRadius: Double = 0.22
    
    // 9. 根據射中的地方所發現的事情
    var findingsFromShots: String = ""
}
