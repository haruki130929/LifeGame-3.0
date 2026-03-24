import Foundation
import Combine

/// Watch 端輕量資料管理
/// 目前用 UserDefaults 儲存，未來可接 App Group 與 iOS 同步
@MainActor
final class WatchDataStore: ObservableObject {

    // MARK: - 狀態 (HP / FP / MP)

    @Published var hp: Stat = Stat(current: 100, max: 100)
    @Published var fp: Stat = Stat(current: 100, max: 100)
    @Published var mp: Stat = Stat(current: 40, max: 60)

    // MARK: - 心情

    @Published var todayMoodEntries: [MoodEntry] = []

    // MARK: - 待辦

    @Published var todoItems: [TodoItem] = []

    // MARK: - Storage

    private let defaults = UserDefaults(suiteName: "group.com.haruki.lifegame") ?? .standard

    init() {
        loadAll()
    }

    // MARK: - 心情操作

    func recordMood(value: Int) {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH"
        let hourKey = fmt.string(from: Date())

        // 覆寫同一小時的記錄
        if let idx = todayMoodEntries.firstIndex(where: { $0.hourKey == hourKey }) {
            todayMoodEntries[idx].value = value
        } else {
            let entry = MoodEntry(id: hourKey, hourKey: hourKey, value: value)
            todayMoodEntries.append(entry)
        }
        saveMood()
    }

    // MARK: - 待辦操作

    func toggleTodo(_ item: TodoItem) {
        guard let idx = todoItems.firstIndex(where: { $0.id == item.id }) else { return }
        todoItems[idx].isDone.toggle()
        saveTodos()
    }

    // MARK: - Persistence

    // 共用 key（與 iOS 端 SharedConstants.Keys 對應）
    private enum Keys {
        static let stats = "shared.stats"
        static let mood = "shared.mood"
        static let todos = "shared.todos"
        static let watchMoodUpdatedAt = "shared.watchMoodUpdatedAt"
        static let watchTodosUpdatedAt = "shared.watchTodosUpdatedAt"
    }

    private func loadAll() {
        // HP / FP / MP
        if let data = defaults.data(forKey: Keys.stats),
           let stats = try? JSONDecoder().decode(WatchStats.self, from: data) {
            hp = stats.hp
            fp = stats.fp
            mp = stats.mp
        }

        // Mood
        if let data = defaults.data(forKey: Keys.mood),
           let entries = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            todayMoodEntries = entries
        }

        // Todos
        if let data = defaults.data(forKey: Keys.todos),
           let items = try? JSONDecoder().decode([TodoItem].self, from: data) {
            todoItems = items
        }
    }

    func saveStats() {
        let stats = WatchStats(hp: hp, fp: fp, mp: mp)
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: Keys.stats)
        }
    }

    private func saveMood() {
        if let data = try? JSONEncoder().encode(todayMoodEntries) {
            defaults.set(data, forKey: Keys.mood)
            // 標記 Watch 有更新，讓 iOS 知道要來讀取
            defaults.set(Date().timeIntervalSince1970, forKey: Keys.watchMoodUpdatedAt)
        }
    }

    private func saveTodos() {
        if let data = try? JSONEncoder().encode(todoItems) {
            defaults.set(data, forKey: Keys.todos)
            defaults.set(Date().timeIntervalSince1970, forKey: Keys.watchTodosUpdatedAt)
        }
    }
}

// MARK: - Codable wrapper for Stat

private struct WatchStats: Codable {
    var hp: Stat
    var fp: Stat
    var mp: Stat
}

// 讓 Stat 支援 Codable（Watch 端需要）
extension Stat: Codable {
    enum CodingKeys: String, CodingKey {
        case current, max
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        current = try c.decode(Int.self, forKey: .current)
        max = try c.decode(Int.self, forKey: .max)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(current, forKey: .current)
        try c.encode(max, forKey: .max)
    }
}
