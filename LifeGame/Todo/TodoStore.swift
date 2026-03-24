import Foundation
import Combine
import SwiftUI

@MainActor
final class TodoQuadrantStore: ObservableObject {
    
    private let storageKey = "todo_quadrant_v1"
    
    @Published var items: [TodoItem] = [] {
        didSet { save() }
    }
    
    init() {
        load()

        // 接收 Watch 傳來的待辦變更
        WatchChangeObserver.shared.onTodoItemsFromWatch = { [weak self] watchItems in
            self?.mergeFromWatch(watchItems)
        }
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
    
    // MARK: - Watch 合併

    /// 將 Watch 傳來的 TodoItem 合併回 iOS（主要是 isDone 狀態）
    private func mergeFromWatch(_ watchItems: [TodoItem]) {
        var changed = false

        for watchItem in watchItems {
            if let idx = items.firstIndex(where: { $0.id == watchItem.id }) {
                if items[idx].isDone != watchItem.isDone {
                    items[idx].isDone = watchItem.isDone
                    changed = true
                }
            }
        }

        if changed {
            debugLog("✅ 已合併 Watch 待辦變更")
            // items 的 didSet 會自動觸發 save()
        }
    }

    private func load() {
        if let saved: [TodoItem] = StorageManager.load([TodoItem].self, forKey: storageKey) {
            items = saved
        } else {
            items = []
        }
        
        // 不再塞預設資料，讓使用者自行新增
    }
    
    private func save() {
        StorageManager.save(items, forKey: storageKey)
        WatchSyncHelper.syncTodos(items)
    }
}
