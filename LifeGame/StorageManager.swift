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
                debugLog("StorageManager.save: coordinator 尚未初始化，跳過")
                return
            }

            var descriptor = FetchDescriptor<KeyValueRecord>(
                predicate: #Predicate { $0.key == key }
            )
            descriptor.fetchLimit = 1
            let existing = try context.fetch(descriptor).first

            if let existing {
                existing.data = data
                existing.updatedAt = .now
            } else {
                context.insert(KeyValueRecord(key: key, data: data))
            }

            try context.save()
        } catch {
            debugLog("Storage save failed:", error)
        }
    }

    @MainActor
    static func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        do {
            guard let context = mainContext else {
                debugLog("StorageManager.load: coordinator 尚未初始化，跳過")
                return nil
            }

            var descriptor = FetchDescriptor<KeyValueRecord>(
                predicate: #Predicate { $0.key == key }
            )
            descriptor.fetchLimit = 1
            guard let record = try context.fetch(descriptor).first else {
                return nil
            }
            return try JSONDecoder().decode(type, from: record.data)
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
        }
    }
}
