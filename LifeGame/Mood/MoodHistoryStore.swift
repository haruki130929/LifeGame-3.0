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

    // MARK: - Persistence (StorageManager → SwiftData)

    private func save() {
        StorageManager.save(points, forKey: saveKey)
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
