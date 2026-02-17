import Foundation

/// 用來包住實際資料，未來 schema 變更可以 migration
struct VersionedBox<T: Codable>: Codable {
    var version: Int
    var payload: T
}
