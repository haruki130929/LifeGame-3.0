import SwiftUI
import Combine

@MainActor
final class AppDataContainer: ObservableObject {
    // SwiftData 版：不再需要 FileStore
    
    // 內容資料（SwiftData）
    lazy var dailyLogStore = DailyLogStore()
    lazy var todoStore = TodoQuadrantStore()
    
    // 其他你之後慢慢搬：wishStore、ledgerStore、weekReviewStore、mandalaStore、tomorrowRingStore...
}
