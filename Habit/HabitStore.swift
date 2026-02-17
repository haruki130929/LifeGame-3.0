//HabitStore
import Foundation
import SwiftUI

final class HabitStore: ObservableObject {
    // MARK: - Storage keys
    @AppStorage("habits_v1") private var habitsData: Data = Data()
    @AppStorage("habit_done_v1") private var doneData: Data = Data()
    
    // MARK: - Published
    @Published var habits: [Habit] = [] {
        didSet { saveHabits() }
    }
    
    /// habitID -> Set(dateKeyString)
    @Published private(set) var doneMap: [UUID: Set<String>] = [:] {
        didSet { saveDone() }
    }
    
    // MARK: - Init
    init() {
        loadHabits()
        loadDone()
        
        // 如果是第一次啟動，給一點預設（想空白也可以把這段刪掉）
        if habits.isEmpty {
            habits = [
                Habit(name: "喝水", icon: "waterbottle", isActive: true),
                Habit(name: "日文", icon: "character.book.closed", isActive: true),
                Habit(name: "散步", icon: "figure.walk", isActive: true)
            ]
        }
    }
    
    // MARK: - CRUD
    func add(_ habit: Habit) {
        habits.append(habit)
    }
    
    func update(_ habit: Habit) {
        if let idx = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[idx] = habit
        }
    }
    
    func delete(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        doneMap[habit.id] = nil
    }
    
    // MARK: - Check-in (打卡)
    func toggle(habit: Habit, date: Date = Date()) {
        let key = dateKey(date)
        var set = doneMap[habit.id] ?? []
        
        if set.contains(key) {
            set.remove(key)
        } else {
            set.insert(key)
        }
        doneMap[habit.id] = set
    }
    
    func isDone(_ habit: Habit, on date: Date) -> Bool {
        let key = dateKey(date)
        return (doneMap[habit.id] ?? []).contains(key)
    }
    
    func isDoneToday(_ habit: Habit) -> Bool {
        isDone(habit, on: Date())
    }
    
    // MARK: - Streak
    /// 連續完成天數（預設以今天為截止）
    func streak(for habit: Habit, asOf date: Date = Date()) -> Int {
        var count = 0
        var cursor = calendar.startOfDay(for: date)
        
        while true {
            if isDone(habit, on: cursor) {
                count += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
                cursor = prev
            } else {
                break
            }
        }
        return count
    }
    
    // MARK: - Weekly completion rate (本週完成率)
    /// 本週（週一～週日）完成率：0.0～1.0
    func weeklyRate(for habit: Habit, weekOf date: Date = Date()) -> Double {
        let days = weekDates(containing: date)
        guard !days.isEmpty else { return 0 }
        let doneCount = days.filter { isDone(habit, on: $0) }.count
        return Double(doneCount) / Double(days.count)
    }
    
    /// 全部啟用習慣的平均本週完成率
    func overallWeeklyRate(weekOf date: Date = Date()) -> Double {
        let active = habits.filter { $0.isActive }
        guard !active.isEmpty else { return 0 }
        let total = active.map { weeklyRate(for: $0, weekOf: date) }.reduce(0, +)
        return total / Double(active.count)
    }
    
    // MARK: - Helpers: week
    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2 // 週一
        return c
    }()
    
    /// 取得「包含該日期」的那一週：週一～週日（7 天）
    func weekDates(containing date: Date) -> [Date] {
        let start = startOfWeek(for: date)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
    
    private func startOfWeek(for date: Date) -> Date {
        let day = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: day) // 1..7
        // firstWeekday = 2 (Mon). 讓 Mon 變成 offset 0
        let diff = (weekday - calendar.firstWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: -diff, to: day) ?? day
    }
    
    private func dateKey(_ date: Date) -> String {
        let d = calendar.startOfDay(for: date)
        let y = calendar.component(.year, from: d)
        let m = calendar.component(.month, from: d)
        let dd = calendar.component(.day, from: d)
        return String(format: "%04d-%02d-%02d", y, m, dd)
    }
    
    // MARK: - Persistence
    private func saveHabits() {
        do {
            habitsData = try JSONEncoder().encode(habits)
        } catch {
            // 先不處理也沒關係，功能優先
        }
    }
    
    private func loadHabits() {
        guard !habitsData.isEmpty else { habits = []; return }
        do {
            habits = try JSONDecoder().decode([Habit].self, from: habitsData)
        } catch {
            habits = []
        }
    }
    
    private func saveDone() {
        // 把 Set 轉成 Array 才好 Codable
        let codable = doneMap.mapValues { Array($0) }
        do {
            doneData = try JSONEncoder().encode(codable)
        } catch {
        }
    }
    
    private func loadDone() {
        guard !doneData.isEmpty else { doneMap = [:]; return }
        do {
            let decoded = try JSONDecoder().decode([UUID: [String]].self, from: doneData)
            doneMap = decoded.mapValues { Set($0) }
        } catch {
            doneMap = [:]
        }
    }
}
