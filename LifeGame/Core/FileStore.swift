import Foundation
import SwiftData

enum FileStoreError: Error {
    case encodeFailed
    case decodeFailed
    case coordinatorNotReady
}

/// 用 SwiftData 的 KeyValueRecord 存 Codable（以 filename 當 key）
final class FileStore {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private static let documentsDirectory: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL.temporaryDirectory
    }()

    init(
        directory: URL = FileStore.documentsDirectory,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        // directory 參數保留：避免外部呼叫端需要改（但 SwiftData 版本不使用它）
        self.encoder = encoder
        self.decoder = decoder

        // 建議：可讀性（debug）
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func url(for filename: String) -> URL {
        // 為了相容外部可能用 url(for:) 做 debug/顯示，我們仍回傳一個看起來合理的路徑
        // （但實際不會寫入檔案）
        Self.documentsDirectory.appendingPathComponent(filename)
    }

    // MARK: - Private helper

    private func makeContext() throws -> ModelContext {
        guard let coord = StorageManager.coordinator else {
            throw FileStoreError.coordinatorNotReady
        }
        return ModelContext(coord.modelContainer)
    }

    // MARK: - CRUD

    func load<T: Decodable>(_ type: T.Type, from filename: String) throws -> T {
        let context = try makeContext()
        let descriptor = FetchDescriptor<KeyValueRecord>(
            predicate: #Predicate { $0.key == filename }
        )

        guard let record = try context.fetch(descriptor).first else {
            throw FileStoreError.decodeFailed
        }

        do {
            return try decoder.decode(T.self, from: record.data)
        } catch {
            throw FileStoreError.decodeFailed
        }
    }

    func save<T: Encodable>(_ value: T, to filename: String) throws {
        let data: Data
        do {
            data = try encoder.encode(value)
        } catch {
            throw FileStoreError.encodeFailed
        }

        let context = try makeContext()
        let descriptor = FetchDescriptor<KeyValueRecord>(
            predicate: #Predicate { $0.key == filename }
        )
        let existing = try context.fetch(descriptor).first

        if let existing {
            existing.data = data
        } else {
            context.insert(KeyValueRecord(key: filename, data: data))
        }

        try context.save()
    }

    func exists(_ filename: String) -> Bool {
        do {
            let context = try makeContext()
            let descriptor = FetchDescriptor<KeyValueRecord>(
                predicate: #Predicate { $0.key == filename }
            )
            return try context.fetchCount(descriptor) > 0
        } catch {
            return false
        }
    }

    func delete(_ filename: String) throws {
        let context = try makeContext()
        let descriptor = FetchDescriptor<KeyValueRecord>(
            predicate: #Predicate { $0.key == filename }
        )

        if let record = try context.fetch(descriptor).first {
            context.delete(record)
            try context.save()
        }
    }
}
