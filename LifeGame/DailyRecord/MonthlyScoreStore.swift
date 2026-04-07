import Foundation
import Combine
import SwiftUI

@MainActor
final class MonthlyScoreStore: ObservableObject {
    
    // MARK: - Storage
    private static let storageKey = "monthly_scores_by_day_v1"
    private var syncHelper: StoreSyncHelper?
    private var isReloading = false

    /// key: "yyyy-MM-dd" -> score (Int)
    @Published private(set) var scoresByDay: [String: Int] = [:] {
        didSet { if !isReloading { save() } }
    }
    
    /// （可選）給某些舊 UI 綁定用：當成「今天分數」
    /// 你的 MonthlyScoreCalendarCardLarge 沒用到這個，但保留也不會壞。
    @Published var score: Int = 0 {
        didSet { setScore(score, for: Date()) }
    }
    
    init() {
        load()
        score = score(for: Date()) ?? 0
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    func reloadFromStorage() {
        isReloading = true
        defer { isReloading = false }
        if let saved: [String: Int] = StorageManager.load([String: Int].self, forKey: Self.storageKey) {
            scoresByDay = saved
        }
        score = score(for: Date()) ?? 0
    }
    
    // MARK: - API (✅ 對齊 MonthlyScoreCalendarCardLarge)
    
    /// 讀取某一天的分數：沒有就回 nil
    func score(for date: Date) -> Int? {
        scoresByDay[dayKey(date)]
    }
    
    /// 設定某一天的分數：傳 nil 代表刪除
    func setScore(_ newScore: Int?, for date: Date) {
        let key = dayKey(date)
        if let v = newScore {
            scoresByDay[key] = v
        } else {
            scoresByDay.removeValue(forKey: key)
        }
        // scoresByDay didSet 會自動 save()
    }
    
    /// 舊碼可能會用 monthlyScoreStore.setScore(5)（當成今天）
    func setScore(_ newScore: Int) {
        setScore(newScore, for: Date())
        score = newScore
    }
    
    /// 取得某個月份所有分數（方便需要時做統計/顯示）
    func scores(in month: Date) -> [String: Int] {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .month, for: month) else { return [:] }
        
        var result: [String: Int] = [:]
        for (k, v) in scoresByDay {
            if let d = parseDayKey(k), d >= interval.start && d < interval.end {
                result[k] = v
            }
        }
        return result
    }
    
    // MARK: - Persistence (SwiftData via StorageManager)
    
    private func save() {
        StorageManager.save(scoresByDay, forKey: Self.storageKey)
    }
    
    private func load() {
        if let saved: [String: Int] = StorageManager.load([String: Int].self, forKey: Self.storageKey) {
            scoresByDay = saved
        } else {
            scoresByDay = [:]
        }
    }
    
    // MARK: - Helpers
    
    private func dayKey(_ date: Date) -> String {
        let d = Calendar.current.startOfDay(for: date)
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }
    
    private func parseDayKey(_ key: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: key)
    }
}
