import SwiftUI
import Observation

/// 追蹤使用者是否已看過各功能頁的教學
@Observable
final class FeatureTutorialTracker {

    /// 功能頁 key，每個對應 TutorialData 裡的一個 TutorialItem
    enum FeatureKey: String, CaseIterable, Equatable {
        case hpFpMp         // HP / FP / MP
        case dailySettle    // 每日結算
        case equipment      // 裝備系統
        case calendar       // 行事曆
        case todoQuadrant   // 待辦四象限
        case timeRing       // 時間圓環
        case dailyLog       // 每日紀錄
        case moodThermometer // 心情溫度計
        case bag            // 整理書包
        case mandala        // 曼陀羅圖表
        case monthlyScore   // 本月結算
        case finance        // 願望 & 記帳
    }

    private let storageKey = "tutorial.seenFeatures"

    /// 已看過教學的功能 key set
    private var seenKeys: Set<String> = []

    /// 是否已從 StorageManager 載入過
    private var hasLoaded = false

    init() {
        // 不在 init 裡載入，因為 StorageManager.coordinator 可能尚未設定
    }

    /// 確保已從持久化儲存載入 seenKeys（延遲載入）
    private func ensureLoaded() {
        guard !hasLoaded, StorageManager.coordinator != nil else { return }
        let saved: [String]? = StorageManager.load([String].self, forKey: storageKey)
        seenKeys = Set(saved ?? [])
        hasLoaded = true
    }

    /// 是否應該顯示該功能的教學（尚未看過）
    func shouldShowTutorial(for key: FeatureKey) -> Bool {
        ensureLoaded()
        return !seenKeys.contains(key.rawValue)
    }

    /// 標記為已看過
    func markAsSeen(_ key: FeatureKey) {
        ensureLoaded()
        seenKeys.insert(key.rawValue)
        let array = Array(seenKeys)
        StorageManager.save(array, forKey: storageKey)
    }

    /// 重置全部（供設定頁使用）
    func resetAll() {
        seenKeys.removeAll()
        hasLoaded = true
        StorageManager.save([String](), forKey: storageKey)
    }
}
