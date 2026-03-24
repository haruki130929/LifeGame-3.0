import Foundation
import Combine

struct MoodPoint: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let score: Double
    
    init(id: UUID = UUID(), timestamp: Date = Date(), score: Double) {
        self.id = id
        self.timestamp = timestamp
        self.score = score
    }
}

@MainActor
final class MoodHistoryStore: ObservableObject {
    @Published private(set) var points: [MoodPoint] = []

    private let saveKey = "mood_history_points_v1"

    init() {
        migrateFromUserDefaultsIfNeeded()
        load()
    }

    @discardableResult
    func add(score: Double, at date: Date = Date()) -> Bool {
        let clamped = min(10, max(0, score))

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

        points.append(MoodPoint(timestamp: date, score: clamped))
        points.sort { $0.timestamp < $1.timestamp }
        save()
        return true
    }

    func points(in range: ClosedRange<Date>) -> [MoodPoint] {
        points.filter { range.contains($0.timestamp) }
    }

    /// 更新已有記錄的分數
    func update(id: UUID, score: Double) {
        guard let idx = points.firstIndex(where: { $0.id == id }) else { return }
        let old = points[idx]
        points[idx] = MoodPoint(id: old.id, timestamp: old.timestamp, score: min(10, max(0, score)))
        save()
    }

    /// 同一小時有記錄就更新，沒有就新增
    @discardableResult
    func addOrUpdate(score: Double, forHour date: Date) -> Bool {
        let calendar = Calendar.current
        guard let hourStart = calendar.dateInterval(of: .hour, for: date)?.start else { return false }
        let clamped = min(10, max(0, score))

        if let idx = points.firstIndex(where: {
            calendar.dateInterval(of: .hour, for: $0.timestamp)?.start == hourStart
        }) {
            let old = points[idx]
            points[idx] = MoodPoint(id: old.id, timestamp: old.timestamp, score: clamped)
        } else {
            points.append(MoodPoint(timestamp: date, score: clamped))
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

    // MARK: - Persistence (StorageManager → SwiftData)

    private func save() {
        StorageManager.save(points, forKey: saveKey)
        syncMoodToWatch()
    }

    /// 將今日的心情記錄同步到 Watch
    private func syncMoodToWatch() {
        let calendar = Calendar.current
        let todayEntries = points
            .filter { calendar.isDateInToday($0.timestamp) }
            .map { point -> MoodEntry in
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyy-MM-dd HH"
                let hourKey = fmt.string(from: point.timestamp)
                return MoodEntry(id: hourKey, hourKey: hourKey, value: Int(point.score))
            }
        WatchSyncHelper.syncMoodEntries(todayEntries)
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
