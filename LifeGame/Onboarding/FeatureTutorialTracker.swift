import SwiftUI

/// 追蹤使用者是否已看過各功能頁的教學
final class FeatureTutorialTracker: ObservableObject {

    /// 功能頁 key，每個對應 TutorialData 裡的一個 TutorialItem
    enum FeatureKey: String, CaseIterable {
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
    private var seenKeys: Set<String> {
        didSet {
            let array = Array(seenKeys)
            StorageManager.save(array, forKey: storageKey)
        }
    }

    init() {
        let saved: [String]? = StorageManager.load([String].self, forKey: storageKey)
        self.seenKeys = Set(saved ?? [])
    }

    /// 是否應該顯示該功能的教學（尚未看過）
    func shouldShowTutorial(for key: FeatureKey) -> Bool {
        !seenKeys.contains(key.rawValue)
    }

    /// 標記為已看過
    func markAsSeen(_ key: FeatureKey) {
        seenKeys.insert(key.rawValue)
        objectWillChange.send()
    }

    /// 重置全部（供設定頁使用）
    func resetAll() {
        seenKeys.removeAll()
        objectWillChange.send()
    }
}
