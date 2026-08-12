import Foundation
import SwiftData

/// 統一儲存 API — 所有 Store 共用，內部透過 StorageCoordinator 的 mainContext 運作
/// 使用共享的 mainContext（與 KeyValueStore 一致），避免每次操作都建立新 context
enum StorageManager {

    /// StorageCoordinator 初始化後會設定這個，確保使用正確的容器
    @MainActor
    static var coordinator: StorageCoordinator?

    @MainActor
    private static var mainContext: ModelContext? {
        coordinator?.mainContext
    }

    @MainActor
    static func save<T: Codable>(_ value: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(value)

            guard let context = mainContext else {
                debugLog("StorageManager.save: coordinator 尚未初始化，跳過 key=\(key)")
                ErrorManager.shared.showError(String(localized: "儲存系統尚未就緒，資料可能未儲存"))
                return
            }

            var descriptor = FetchDescriptor<KeyValueRecord>(
                predicate: #Predicate { $0.key == key }
            )
            descriptor.sortBy = [SortDescriptor(\.updatedAt, order: .reverse)]
            let records = try context.fetch(descriptor)

            if let newest = records.first {
                newest.data = data
                newest.updatedAt = .now
                // 清理 CloudKit 同步造成的重複 record
                for dup in records.dropFirst() {
                    context.delete(dup)
                }
            } else {
                context.insert(KeyValueRecord(key: key, data: data))
            }

            try context.save()
        } catch {
            debugLog("Storage save failed:", error)
            ErrorManager.shared.showError(L10n.Error.saveFailed, error: error)
        }
    }

    @MainActor
    static func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        do {
            guard let context = mainContext else {
                debugLog("StorageManager.load: coordinator 尚未初始化，跳過 key=\(key)")
                return nil
            }

            var descriptor = FetchDescriptor<KeyValueRecord>(
                predicate: #Predicate { $0.key == key }
            )
            descriptor.sortBy = [SortDescriptor(\.updatedAt, order: .reverse)]
            let records = try context.fetch(descriptor)

            guard let newest = records.first else {
                return nil
            }

            // 收斂多筆（CloudKit 衝突）：有註冊 merger → 合併，否則取最新（LWW）
            let resolved = KeyValueMergeRegistry.resolvedData(forKey: key, records: records) ?? newest.data
            if records.count > 1 {
                newest.data = resolved
                newest.updatedAt = .now
                for dup in records.dropFirst() {
                    context.delete(dup)
                }
                try context.save()
                debugLog("Storage: key=\(key) 收斂 \(records.count) 筆 → 1\(KeyValueMergeRegistry.hasMerger(for: key) ? "（已合併）" : "（取最新）")")
            }

            return try JSONDecoder().decode(type, from: resolved)
        } catch {
            debugLog("Storage load failed:", error)
            return nil
        }
    }

    @MainActor
    static func remove(forKey key: String) {
        do {
            guard let context = mainContext else {
                debugLog("StorageManager.remove: coordinator 尚未初始化，跳過")
                return
            }

            var descriptor = FetchDescriptor<KeyValueRecord>(
                predicate: #Predicate { $0.key == key }
            )
            descriptor.fetchLimit = 1
            if let record = try context.fetch(descriptor).first {
                context.delete(record)
                try context.save()
            }
        } catch {
            debugLog("Storage remove failed:", error)
            ErrorManager.shared.showError(L10n.Error.deleteFailed, error: error)
        }
    }
}
