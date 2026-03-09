import Foundation
import Combine
import SwiftUI
import Combine

@MainActor
final class TodoQuadrantStore: ObservableObject {
    
    private let storageKey = "todo_quadrant_v1"
    
    @Published var items: [TodoItem] = [] {
        didSet { save() }
    }
    
    init() {
        load()
    }
    
    func add(title: String, quadrant: TodoQuadrant) {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        items.insert(TodoItem(title: t, quadrant: quadrant), at: 0)
    }
    
    func toggleDone(_ item: TodoItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isDone.toggle()
    }
    
    func delete(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
    }
    
    func items(in quadrant: TodoQuadrant) -> [TodoItem] {
        items
            .filter { $0.quadrant == quadrant }
            .sorted {
                if $0.isDone != $1.isDone { return $0.isDone == false }
                return $0.createdAt > $1.createdAt
            }
    }
    
    func previewItems(in quadrant: TodoQuadrant, limit: Int) -> [TodoItem] {
        Array(items(in: quadrant).prefix(limit))
    }
    
    private func load() {
        if let saved: [TodoItem] = StorageManager.load([TodoItem].self, forKey: storageKey) {
            items = saved
        } else {
            items = []
        }
        
        // ✅ 若完全沒有資料，才塞 sample（避免污染正式使用者）
        if items.isEmpty {
            items = [
                TodoItem(title: "複習日文課文", quadrant: .importantNotUrgent),
                TodoItem(title: "明天要交的作業", quadrant: .importantUrgent),
                TodoItem(title: "整理桌面", quadrant: .notImportantNotUrgent),
                TodoItem(title: "回覆訊息", quadrant: .urgentNotImportant)
            ]
        }
    }
    
    private func save() {
        StorageManager.save(items, forKey: storageKey)
    }
}
