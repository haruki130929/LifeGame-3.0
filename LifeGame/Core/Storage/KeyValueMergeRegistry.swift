import Foundation

/// 跨裝置同步衝突合併註冊表。
///
/// CloudKit 可能為同一個 key 產生多筆 `KeyValueRecord`（兩台裝置離線各自修改後同步）。
/// 預設收斂行為是「取 `updatedAt` 最新、丟掉其餘」(last-write-wins)，會遺失另一台的修改。
///
/// 集合型資料（陣列/字典）可在此註冊 merger，改用 **union-by-id** 合併：
/// 兩台各自新增的項目都會保留，只有「同一個 id 被兩邊都改」時才退回較新版本。
///
/// 安全性：任何 merger 解碼失敗（型別不符或資料異常）一律**退回最新一包（LWW）**，
/// 絕不會產生空集合或覆蓋掉資料——最壞情況就是退回成原本的行為。
enum KeyValueMergeRegistry {

    /// key -> merge(blobs: 由舊到新排序) -> 合併後的 Data
    private static var mergers: [String: ([Data]) -> Data] = [:]

    static func register(_ key: String, merge: @escaping ([Data]) -> Data) {
        mergers[key] = merge
    }

    static func hasMerger(for key: String) -> Bool { mergers[key] != nil }

    /// 給定同一個 key 的多筆 record，回傳「應保留的合併後 Data」。
    /// - 有註冊 merger 且超過一筆 → 合併
    /// - 否則 → 最新一筆（LWW）
    static func resolvedData(forKey key: String, records: [KeyValueRecord]) -> Data? {
        guard !records.isEmpty else { return nil }
        let newestFirst = records.sorted { $0.updatedAt > $1.updatedAt }
        guard records.count > 1, let merge = mergers[key] else {
            return newestFirst.first?.data
        }
        let oldestFirst = Array(newestFirst.reversed().map(\.data))
        return merge(oldestFirst)
    }

    // MARK: - 通用合併器

    /// 陣列型：union by id，相同 id 取較新版本（blobs 由舊到新）。
    static func arrayMerge<T: Codable & Identifiable>(_ type: T.Type) -> ([Data]) -> Data {
        return { blobs in
            guard let newest = blobs.last else { return Data() }
            var byId: [T.ID: T] = [:]
            var order: [T.ID] = []
            for blob in blobs {   // 由舊到新；較新者覆蓋同一個 id
                guard let arr = try? JSONDecoder().decode([T].self, from: blob) else {
                    debugLog("⚠️ KeyValueMerge: [\(T.self)] 解碼失敗，退回 LWW")
                    return newest
                }
                for item in arr {
                    if byId[item.id] == nil { order.append(item.id) }
                    byId[item.id] = item
                }
            }
            let merged = order.compactMap { byId[$0] }
            return (try? JSONEncoder().encode(merged)) ?? newest
        }
    }

    /// 字典型（[String: V]）：union of keys，相同 key 取較新值（blobs 由舊到新）。
    static func dictMerge<V: Codable>(_ valueType: V.Type) -> ([Data]) -> Data {
        return { blobs in
            guard let newest = blobs.last else { return Data() }
            var merged: [String: V] = [:]
            for blob in blobs {   // 由舊到新；較新者覆蓋同一個 key
                guard let dict = try? JSONDecoder().decode([String: V].self, from: blob) else {
                    debugLog("⚠️ KeyValueMerge: [String:\(V.self)] 解碼失敗，退回 LWW")
                    return newest
                }
                for (k, v) in dict { merged[k] = v }
            }
            return (try? JSONEncoder().encode(merged)) ?? newest
        }
    }
}
