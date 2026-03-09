import SwiftUI

struct ScheduleBlock: Identifiable, Codable, Equatable {
    var id = UUID()
    var startHour: Int      // 0...23
    var endHour: Int        // 1...24, 且 endHour > startHour
    var title: String
}

extension Array where Element == ScheduleBlock {
    /// 把 24 小時的「每小時文字」壓成連續區段（圓餅才會好看）
    static func blocks(from hourlyTitles: [String]) -> [ScheduleBlock] {
        guard hourlyTitles.count == 24 else { return [] }
        
        var result: [ScheduleBlock] = []
        var i = 0
        while i < 24 {
            let t = hourlyTitles[i].trimmingCharacters(in: .whitespacesAndNewlines)
            let start = i
            var j = i + 1
            while j < 24 {
                let tj = hourlyTitles[j].trimmingCharacters(in: .whitespacesAndNewlines)
                if tj != t { break }
                j += 1
            }
            // 只有「非空」才產生區段
            if !t.isEmpty {
                result.append(ScheduleBlock(startHour: start, endHour: j, title: t))
            }
            i = j
        }
        return result
    }
}
