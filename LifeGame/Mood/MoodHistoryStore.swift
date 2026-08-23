import Foundation
import Combine

struct MoodPoint: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let score: Double
    var focus: Double?
    var fatigue: Double?

    init(id: UUID = UUID(), timestamp: Date = Date(), score: Double, focus: Double? = nil, fatigue: Double? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.score = score
        self.focus = focus
        self.fatigue = fatigue
    }
}

@MainActor
final class MoodHistoryStore: ObservableObject {
    @Published private(set) var points: [MoodPoint] = []

    private let saveKey = "mood_history_points_v1"
    private var syncHelper: StoreSyncHelper?

    init() {
        migrateFromUserDefaultsIfNeeded()
        load()

        // 接收 Watch 傳來的心情資料
        WatchChangeObserver.shared.onMoodEntriesFromWatch = { [weak self] entries in
            self?.mergeFromWatch(entries)
        }
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    func reloadFromStorage() {
        if let saved: [MoodPoint] = StorageManager.load([MoodPoint].self, forKey: saveKey) {
            points = saved
            points.sort { $0.timestamp < $1.timestamp }
        }
    }

    @discardableResult
    func add(score: Double, focus: Double? = nil, fatigue: Double? = nil, at date: Date = Date()) -> Bool {
        let clamped = min(10, max(0, score))
        let clampedFocus = focus.map { min(10, max(0, $0)) }
        let clampedFatigue = fatigue.map { min(10, max(0, $0)) }

        let calendar = Calendar.current
        guard let hourStart = calendar.dateInterval(of: .hour, for: date)?.start else {
            return false
        }

        if let last = points.last {
            guard let lastHourStart = calendar.dateInterval(of: .hour, for: last.timestamp)?.start else {
                return false
            }
            if lastHourStart == hourStart {
                return false
            }
        }

        points.append(MoodPoint(timestamp: date, score: clamped, focus: clampedFocus, fatigue: clampedFatigue))
        points.sort { $0.timestamp < $1.timestamp }
        save()
        return true
    }

    func points(in range: ClosedRange<Date>) -> [MoodPoint] {
        points.filter { range.contains($0.timestamp) }
    }

    /// 更新已有記錄的分數
    func update(id: UUID, score: Double, focus: Double? = nil, fatigue: Double? = nil) {
        guard let idx = points.firstIndex(where: { $0.id == id }) else { return }
        let old = points[idx]
        points[idx] = MoodPoint(
            id: old.id, timestamp: old.timestamp,
            score: min(10, max(0, score)),
            focus: focus.map { min(10, max(0, $0)) } ?? old.focus,
            fatigue: fatigue.map { min(10, max(0, $0)) } ?? old.fatigue
        )
        save()
    }

    /// 刪除所有記錄
    func deleteAll() {
        points.removeAll()
        save()
        debugLog("✅ MoodHistory 全部清除")
    }

    /// 刪除指定記錄
    func delete(id: UUID) {
        points.removeAll { $0.id == id }
        save()
    }

    /// 同一小時有記錄就更新，沒有就新增
    @discardableResult
    func addOrUpdate(score: Double, focus: Double? = nil, fatigue: Double? = nil, forHour date: Date) -> Bool {
        let calendar = Calendar.current
        guard let hourStart = calendar.dateInterval(of: .hour, for: date)?.start else { return false }
        let clamped = min(10, max(0, score))
        let clampedFocus = focus.map { min(10, max(0, $0)) }
        let clampedFatigue = fatigue.map { min(10, max(0, $0)) }

        if let idx = points.firstIndex(where: {
            calendar.dateInterval(of: .hour, for: $0.timestamp)?.start == hourStart
        }) {
            let old = points[idx]
            points[idx] = MoodPoint(id: old.id, timestamp: old.timestamp, score: clamped,
                                     focus: clampedFocus ?? old.focus, fatigue: clampedFatigue ?? old.fatigue)
        } else {
            points.append(MoodPoint(timestamp: date, score: clamped, focus: clampedFocus, fatigue: clampedFatigue))
            points.sort { $0.timestamp < $1.timestamp }
        }
        save()
        return true
    }

    /// 回傳顯示範圍內每個小時的記錄狀態
    func hourlyEntries(in range: ClosedRange<Date>) -> [(hour: Date, point: MoodPoint?)] {
        let calendar = Calendar.current
        var result: [(hour: Date, point: MoodPoint?)] = []
        var current = range.lowerBound

        while current <= range.upperBound {
            let hourStart = calendar.dateInterval(of: .hour, for: current)?.start ?? current
            let match = points.first {
                calendar.dateInterval(of: .hour, for: $0.timestamp)?.start == hourStart
            }
            result.append((hour: hourStart, point: match))
            current = calendar.date(byAdding: .hour, value: 1, to: hourStart) ?? current.addingTimeInterval(3600)
        }
        return result
    }

    // MARK: - Watch 合併

    /// 將 Watch 傳來的 MoodEntry 合併到 iOS 端
    private func mergeFromWatch(_ entries: [MoodEntry]) {
        let calendar = Calendar.current
        var changed = false

        for entry in entries {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd HH"
            guard let date = fmt.date(from: entry.hourKey) else { continue }
            guard let hourStart = calendar.dateInterval(of: .hour, for: date)?.start else { continue }

            let score = Double(entry.value)

            // 同一小時已有記錄就更新，沒有就新增
            if let idx = points.firstIndex(where: {
                calendar.dateInterval(of: .hour, for: $0.timestamp)?.start == hourStart
            }) {
                let old = points[idx]
                if old.score != score {
                    points[idx] = MoodPoint(id: old.id, timestamp: old.timestamp, score: score)
                    changed = true
                }
            } else {
                points.append(MoodPoint(timestamp: date, score: score))
                changed = true
            }
        }

        if changed {
            points.sort { $0.timestamp < $1.timestamp }
            save()
            debugLog("✅ 已合併 Watch 心情資料")
        }
    }

    /// 把外部（Widget／Watch／通知）傳來的心情直接併進「儲存層」，
    /// 不依賴任何 MoodHistoryStore 實例是否存活 —— 給 WatchChangeObserver 呼叫。
    /// 與 TodoQuadrantStore.applyDoneFlags 對稱：避免「實例還沒建好就消耗掉時間戳、導致心情遺失」。
    @MainActor
    static func applyEntries(from entries: [MoodEntry]) {
        let key = "mood_history_points_v1"
        var stored: [MoodPoint] = StorageManager.load([MoodPoint].self, forKey: key) ?? []

        let calendar = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH"
        var changed = false

        for entry in entries {
            guard let date = fmt.date(from: entry.hourKey),
                  let hourStart = calendar.dateInterval(of: .hour, for: date)?.start else { continue }
            let score = Double(entry.value)

            if let idx = stored.firstIndex(where: {
                calendar.dateInterval(of: .hour, for: $0.timestamp)?.start == hourStart
            }) {
                if stored[idx].score != score {
                    let old = stored[idx]
                    stored[idx] = MoodPoint(id: old.id, timestamp: old.timestamp, score: score,
                                            focus: old.focus, fatigue: old.fatigue)
                    changed = true
                }
            } else {
                stored.append(MoodPoint(timestamp: date, score: score))
                changed = true
            }
        }

        if changed {
            stored.sort { $0.timestamp < $1.timestamp }
            StorageManager.save(stored, forKey: key)
            debugLog("✅ 已把外部心情併入 storage（\(entries.count) 筆）")
        }
    }

    // MARK: - Persistence (StorageManager → SwiftData)

    private func save() {
        StorageManager.save(points, forKey: saveKey)
        syncMoodToWatch()
    }

    /// 將今日的心情記錄同步到 Watch
    private func syncMoodToWatch() {
        WatchSyncHelper.syncMoodEntries(Self.todayEntries(from: points))
    }

    /// 今日的心情，轉成共享用的整點形式。
    /// 抽成 static 是為了讓 `WatchSyncHelper.pushSnapshotFromStorage()` 用同一份轉換 ——
    /// 兩邊各寫一份的話，hourKey 的格式遲早會走鐘，而讀的那端是用字串比對整點的。
    static func todayEntries(from points: [MoodPoint], now: Date = Date()) -> [MoodEntry] {
        let calendar = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH"
        return points
            .filter { calendar.isDate($0.timestamp, inSameDayAs: now) }
            .map { point -> MoodEntry in
                let hourKey = fmt.string(from: point.timestamp)
                return MoodEntry(id: hourKey, hourKey: hourKey, value: Int(point.score))
            }
    }

    private func load() {
        if let saved: [MoodPoint] = StorageManager.load([MoodPoint].self, forKey: saveKey) {
            points = saved
            points.sort { $0.timestamp < $1.timestamp }
        }
    }

    // MARK: - 一次性遷移：舊 UserDefaults → StorageManager

    private func migrateFromUserDefaultsIfNeeded() {
        let defaults = UserDefaults.standard
        let migrationFlag = "migrate.moodHistory.toSwiftData.v1"
        guard !defaults.bool(forKey: migrationFlag) else { return }

        if let data = defaults.data(forKey: saveKey),
           let oldPoints = try? JSONDecoder().decode([MoodPoint].self, from: data) {
            StorageManager.save(oldPoints, forKey: saveKey)
            debugLog("✅ MoodHistoryStore migrated \(oldPoints.count) points to SwiftData")
        }

        defaults.set(true, forKey: migrationFlag)
    }
}
