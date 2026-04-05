import Foundation

// MARK: - ClassScheduleV2

struct ClassScheduleV2: Codable, Hashable {
    var coursesByDay: [String: [CourseSlot]] = [:]

    // MARK: - CourseSlot

    struct CourseSlot: Identifiable, Codable, Hashable {
        var id = UUID()
        var title: String
        var startMinute: Int
        var endMinute: Int
        var icon: String = "book"
        var colorHex: String = "5B9BD5"
        var hpCost: Int = 10
        var fpCost: Int = 10
    }

    // MARK: - Accessors

    func courses(for day: Weekday) -> [CourseSlot] {
        coursesByDay[String(day.rawValue)] ?? []
    }

    mutating func setCourses(_ courses: [CourseSlot], for day: Weekday) {
        coursesByDay[String(day.rawValue)] = courses
    }

    mutating func addCourse(_ course: CourseSlot, for day: Weekday) {
        var list = courses(for: day)
        list.append(course)
        list.sort { $0.startMinute < $1.startMinute }
        coursesByDay[String(day.rawValue)] = list
    }

    mutating func updateCourse(_ course: CourseSlot, for day: Weekday) {
        var list = courses(for: day)
        if let idx = list.firstIndex(where: { $0.id == course.id }) {
            list[idx] = course
            list.sort { $0.startMinute < $1.startMinute }
            coursesByDay[String(day.rawValue)] = list
        }
    }

    mutating func removeCourse(id: UUID, for day: Weekday) {
        var list = courses(for: day)
        list.removeAll { $0.id == id }
        coursesByDay[String(day.rawValue)] = list
    }

    // MARK: - Convert to RingItems

    /// Convert today's courses into RingItemV2 array for loading into plan.
    func toRingItems(for day: Weekday) -> [RingItemV2] {
        courses(for: day).map { slot in
            RingItemV2(
                startMinute: slot.startMinute,
                endMinute: slot.endMinute,
                title: slot.title,
                icon: slot.icon,
                colorHex: slot.colorHex,
                hpCost: slot.hpCost,
                fpCost: slot.fpCost,
                source: .classSchedule
            )
        }
    }
}
