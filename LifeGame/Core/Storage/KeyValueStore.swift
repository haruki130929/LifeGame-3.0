import SwiftData
import Foundation

@MainActor
@Observable
final class KeyValueStore {
    private let contextProvider: () -> ModelContext

    init(contextProvider: @escaping () -> ModelContext) {
        self.contextProvider = contextProvider
    }

    // MARK: - Read

    func get<T: Codable>(_ key: String, as type: T.Type) throws -> T? {
        let context = contextProvider()
        let predicate = #Predicate<KeyValueRecord> { $0.key == key }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1

        guard let record = try context.fetch(descriptor).first else {
            return nil
        }

        do {
            return try JSONDecoder().decode(T.self, from: record.data)
        } catch {
            throw StorageError.keyValueDecodingFailed(
                key: key,
                targetType: String(describing: T.self)
            )
        }
    }

    func get<T: Codable>(_ key: String, default defaultValue: T) throws -> T {
        try get(key, as: T.self) ?? defaultValue
    }

    // MARK: - Write

    func set<T: Codable>(_ key: String, value: T) throws {
        let context = contextProvider()
        let encoded: Data
        do {
            encoded = try JSONEncoder().encode(value)
        } catch {
            throw StorageError.keyValueEncodingFailed(key: key)
        }

        let predicate = #Predicate<KeyValueRecord> { $0.key == key }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            existing.data = encoded
            existing.updatedAt = .now
        } else {
            let record = KeyValueRecord(key: key, data: encoded)
            context.insert(record)
        }

        try context.save()
    }

    // MARK: - Delete

    func remove(_ key: String) throws {
        let context = contextProvider()
        let predicate = #Predicate<KeyValueRecord> { $0.key == key }
        let descriptor = FetchDescriptor(predicate: predicate)

        for record in try context.fetch(descriptor) {
            context.delete(record)
        }
        try context.save()
    }

    // MARK: - TypedKey convenience

    func get<T: Codable>(_ key: TypedKey<T>) throws -> T {
        try get(key.rawValue, default: key.defaultValue)
    }

    func set<T: Codable>(_ key: TypedKey<T>, value: T) throws {
        try set(key.rawValue, value: value)
    }
}

// MARK: - TypedKey

struct TypedKey<Value: Codable>: Sendable where Value: Sendable {
    let rawValue: String
    let defaultValue: Value

    init(_ rawValue: String, default defaultValue: Value) {
        self.rawValue = rawValue
        self.defaultValue = defaultValue
    }
}

// MARK: - App-wide keys

extension TypedKey where Value == String {
    static let userName = TypedKey("app.userName", default: String(localized: "冒險者"))
}

extension TypedKey where Value == Bool {
    static let hasCompletedOnboarding = TypedKey("app.hasCompletedOnboarding", default: false)
}
