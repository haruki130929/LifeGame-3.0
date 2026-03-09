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
        load()
    }
    
    @discardableResult
    func add(score: Double, at date: Date = Date()) -> Bool {
        let clamped = min(10, max(0, score))
        
        let calendar = Calendar.current
        let hourStart = calendar.dateInterval(of: .hour, for: date)!.start
        
        if let last = points.last {
            let lastHourStart = calendar.dateInterval(of: .hour, for: last.timestamp)!.start
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
    
    // MARK: - Persistence (UserDefaults + Codable)
    private func save() {
        do {
            let data = try JSONEncoder().encode(points)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("MoodHistoryStore save error:", error)
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        do {
            points = try JSONDecoder().decode([MoodPoint].self, from: data)
            points.sort { $0.timestamp < $1.timestamp }
        } catch {
            print("MoodHistoryStore load error:", error)
        }
    }
}
