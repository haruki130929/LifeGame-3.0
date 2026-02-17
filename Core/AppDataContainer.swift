import SwiftUI

@MainActor
final class AppDataContainer: ObservableObject {
    let fileStore = FileStore()
    
    // 內容資料（Documents）
    lazy var dailyLogStore = DailyLogStore(fileStore: fileStore)
    lazy var todoStore = TodoQuadrantStore(fileStore: fileStore)
    
    // 其他你之後慢慢搬：wishStore、ledgerStore、weekReviewStore、mandalaStore、tomorrowRingStore...
}
