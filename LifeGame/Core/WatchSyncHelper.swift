import Foundation

/// 將 iOS 端資料同步到 App Groups 的 shared UserDefaults，供 watchOS 讀取
enum WatchSyncHelper {

    private static var defaults: UserDefaults { SharedConstants.sharedDefaults }

    // MARK: - Stats (HP / FP / MP)

    static func syncStats(hp: Stat, fp: Stat, mp: Stat) {
        struct StatsPayload: Codable {
            var hp: StatCodable
            var fp: StatCodable
            var mp: StatCodable
        }
        struct StatCodable: Codable {
            var current: Int
            var max: Int
        }

        let payload = StatsPayload(
            hp: StatCodable(current: hp.current, max: hp.max),
            fp: StatCodable(current: fp.current, max: fp.max),
            mp: StatCodable(current: mp.current, max: mp.max)
        )
        if let data = try? JSONEncoder().encode(payload) {
            defaults.set(data, forKey: SharedConstants.Keys.stats)
        }
    }

    // MARK: - Mood (今日心情紀錄)

    static func syncMoodEntries(_ entries: [MoodEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: SharedConstants.Keys.mood)
        }
    }

    // MARK: - Todos (待辦事項)

    static func syncTodos(_ items: [TodoItem]) {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: SharedConstants.Keys.todos)
        }
    }
}
