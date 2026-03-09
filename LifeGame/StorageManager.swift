import Foundation
import SwiftData

/// 舊版 API 相容層 — 所有現有 Store 繼續用 StorageManager.save / .load / .remove
/// 內部改為透過 StorageCoordinator 的容器運作
enum StorageManager {

    /// StorageCoordinator 初始化後會設定這個，確保使用正確的容器
    @MainActor
    static var coordinator: StorageCoordinator?

    @MainActor
    private static var container: ModelContainer {
        guard let coordinator else {
            fatalError("StorageManager: StorageCoordinator 尚未初始化")
        }
        return coordinator.modelContainer
    }

    static func save<T: Codable>(_ value: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(value)

            let context = MainActor.assumeIsolated {
                ModelContext(container)
            }

            let descriptor = FetchDescriptor<KeyValueRecord>(
                predicate: #Predicate { $0.key == key }
            )
            let existing = try context.fetch(descriptor).first

            if let existing {
                existing.data = data
            } else {
                context.insert(KeyValueRecord(key: key, data: data))
            }

            try context.save()
        } catch {
            print("Storage save failed:", error)
        }
    }

    static func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        do {
            let context = MainActor.assumeIsolated {
                ModelContext(container)
            }
            let descriptor = FetchDescriptor<KeyValueRecord>(
                predicate: #Predicate { $0.key == key }
            )
            guard let record = try context.fetch(descriptor).first else {
                return nil
            }
            return try JSONDecoder().decode(type, from: record.data)
        } catch {
            print("Storage load failed:", error)
            return nil
        }
    }

    static func remove(forKey key: String) {
        do {
            let context = MainActor.assumeIsolated {
                ModelContext(container)
            }
            let descriptor = FetchDescriptor<KeyValueRecord>(
                predicate: #Predicate { $0.key == key }
            )
            if let record = try context.fetch(descriptor).first {
                context.delete(record)
                try context.save()
            }
        } catch {
            print("Storage remove failed:", error)
        }
    }
}
