import SwiftUI

final class ScheduleStore: ObservableObject {
    /// 24 格：第 0 格代表 0:00～1:00，第 8 格代表 8:00～9:00
    @Published var hourlyTitles: [String] = Array(repeating: "", count: 24)
    
    var blocks: [ScheduleBlock] {
        .blocks(from: hourlyTitles)
    }
}
