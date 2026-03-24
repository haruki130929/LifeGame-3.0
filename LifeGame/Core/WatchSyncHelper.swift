import Foundation

// MARK: - 共享 Codable 型別（iOS ↔ watchOS 共用）

struct SyncStatCodable: Codable {
    var current: Int
    var max: Int
}

struct SyncStatsPayload: Codable {
    var hp: SyncStatCodable
    var fp: SyncStatCodable
    var mp: SyncStatCodable
}

/// 將 iOS 端資料同步到 App Groups 的 shared UserDefaults，供 watchOS 讀取
enum WatchSyncHelper {

    private static var defaults: UserDefaults { SharedConstants.sharedDefaults }

    // MARK: - Stats (HP / FP / MP)

    static func syncStats(hp: Stat, fp: Stat, mp: Stat) {
        let payload = SyncStatsPayload(
            hp: SyncStatCodable(current: hp.current, max: hp.max),
            fp: SyncStatCodable(current: fp.current, max: fp.max),
            mp: SyncStatCodable(current: mp.current, max: mp.max)
        )
        do {
            let data = try JSONEncoder().encode(payload)
            defaults.set(data, forKey: SharedConstants.Keys.stats)
        } catch {
            debugLog("⚠️ WatchSync: Stats 編碼失敗 - \(error.localizedDescription)")
        }
    }

    // MARK: - Mood (今日心情紀錄)

    static func syncMoodEntries(_ entries: [MoodEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            defaults.set(data, forKey: SharedConstants.Keys.mood)
        } catch {
            debugLog("⚠️ WatchSync: Mood 編碼失敗 - \(error.localizedDescription)")
        }
    }

    // MARK: - Todos (待辦事項)

    static func syncTodos(_ items: [TodoItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            defaults.set(data, forKey: SharedConstants.Keys.todos)
        } catch {
            debugLog("⚠️ WatchSync: Todos 編碼失敗 - \(error.localizedDescription)")
        }
    }
}
