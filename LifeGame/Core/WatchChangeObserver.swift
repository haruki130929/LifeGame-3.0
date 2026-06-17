import Foundation
import Combine

/// 監聽 Watch 透過 App Groups 寫入的變更，合併回 iOS 端
/// 在 App 回前景時自動檢查
@MainActor
final class WatchChangeObserver: ObservableObject {

    static let shared = WatchChangeObserver()

    private let defaults = SharedConstants.sharedDefaults

    /// 上次 iOS 端讀取 Watch 變更的時間（存在本地 UserDefaults）
    private var lastMoodReadTime: TimeInterval {
        get { UserDefaults.standard.double(forKey: "ios.lastWatchMoodRead") }
        set { UserDefaults.standard.set(newValue, forKey: "ios.lastWatchMoodRead") }
    }
    private var lastTodosReadTime: TimeInterval {
        get { UserDefaults.standard.double(forKey: "ios.lastWatchTodosRead") }
        set { UserDefaults.standard.set(newValue, forKey: "ios.lastWatchTodosRead") }
    }

    /// Mood 合併回呼（由 MoodHistoryStore 設定）
    var onMoodEntriesFromWatch: (([MoodEntry]) -> Void)?

    /// Todo 合併回呼（由 TodoStore 設定）
    var onTodoItemsFromWatch: (([TodoItem]) -> Void)?

    private init() {}

    // MARK: - 檢查並合併

    /// App 回前景時呼叫
    func checkForWatchChanges() {
        checkMoodChanges()
        checkTodoChanges()
    }

    private func checkMoodChanges() {
        let watchUpdatedAt = defaults.double(forKey: SharedConstants.Keys.watchMoodUpdatedAt)
        guard watchUpdatedAt > lastMoodReadTime else { return }

        // Watch 有新的 mood 資料
        guard let data = defaults.data(forKey: SharedConstants.Keys.mood),
              let entries = try? JSONDecoder().decode([MoodEntry].self, from: data) else {
            return
        }

        debugLog("📱 偵測到 Watch 心情更新（\(entries.count) 筆）")
        onMoodEntriesFromWatch?(entries)
        lastMoodReadTime = watchUpdatedAt
    }

    private func checkTodoChanges() {
        let watchUpdatedAt = defaults.double(forKey: SharedConstants.Keys.watchTodosUpdatedAt)
        guard watchUpdatedAt > lastTodosReadTime else { return }

        guard let data = defaults.data(forKey: SharedConstants.Keys.todos),
              let items = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return
        }

        debugLog("📱 偵測到 Widget/Watch 待辦更新（\(items.count) 筆）")
        // ① 直接把 isDone 併進 storage（不依賴任何 store 實例是否存活）
        TodoQuadrantStore.applyDoneFlags(from: items)
        // ② 通知記憶體中的 store 實例（即時 UI 更新）
        onTodoItemsFromWatch?(items)
        // ③ 通知所有 store 從 storage 重載（涵蓋雙實例 / 冷啟動沒有 willEnterForeground 的情況）
        NotificationCenter.default.post(name: StorageCoordinator.didReceiveRemoteChange, object: nil)
        lastTodosReadTime = watchUpdatedAt
    }
}
