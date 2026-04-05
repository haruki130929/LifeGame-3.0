import Foundation

// MARK: - WeeklyTemplateV2

struct WeeklyTemplateV2: Codable, Hashable {
    var templatesByDay: [String: [RingItemV2]] = [:]

    func templates(for day: Weekday) -> [RingItemV2] {
        templatesByDay[String(day.rawValue)] ?? []
    }

    mutating func setTemplates(_ items: [RingItemV2], for day: Weekday) {
        templatesByDay[String(day.rawValue)] = items
    }

    mutating func addTemplate(_ item: RingItemV2, for day: Weekday) {
        var list = templates(for: day)
        list.append(item)
        list.sort { $0.startMinute < $1.startMinute }
        templatesByDay[String(day.rawValue)] = list
    }

    mutating func updateTemplate(_ item: RingItemV2, for day: Weekday) {
        var list = templates(for: day)
        if let idx = list.firstIndex(where: { $0.id == item.id }) {
            list[idx] = item
            list.sort { $0.startMinute < $1.startMinute }
            templatesByDay[String(day.rawValue)] = list
        }
    }

    mutating func removeTemplate(id: UUID, for day: Weekday) {
        var list = templates(for: day)
        list.removeAll { $0.id == id }
        templatesByDay[String(day.rawValue)] = list
    }
}

// MARK: - Migration from V1

extension WeeklyTemplateV2 {
    init(from v1: WeeklySchedule) {
        self.templatesByDay = v1.scheduleByDay.mapValues { items in
            items.map { RingItemV2(from: $0) }
        }
    }
}
