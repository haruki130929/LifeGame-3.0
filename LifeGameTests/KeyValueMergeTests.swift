import XCTest
@testable import LifeGame

/// KeyValueMergeRegistry 的跨裝置同步合併邏輯測試（union-by-id）。
///
/// 純函式測試：直接餵編碼後的 blob，檢查合併結果，不碰任何儲存。
final class KeyValueMergeTests: XCTestCase {

    private struct Item: Codable, Identifiable, Equatable {
        var id: UUID
        var name: String
    }

    private let enc = JSONEncoder()
    private let dec = JSONDecoder()

    /// 兩台裝置各自離線新增 → 合併後兩筆都在（這就是要修正的核心情境）
    func testArrayUnionKeepsBothDevicesAdds() throws {
        let shared = Item(id: UUID(), name: "shared")
        let onlyA = Item(id: UUID(), name: "A")
        let onlyB = Item(id: UUID(), name: "B")

        let older = try enc.encode([shared, onlyA])   // 裝置 A
        let newer = try enc.encode([shared, onlyB])   // 裝置 B（較新）

        let merge = KeyValueMergeRegistry.arrayMerge(Item.self)
        let merged = try dec.decode([Item].self, from: merge([older, newer]))

        XCTAssertEqual(Set(merged.map(\.id)), Set([shared.id, onlyA.id, onlyB.id]),
                       "兩台各自新增的項目都應保留")
    }

    /// 同一個 id 兩邊都改 → 取較新一包的版本
    func testArraySameIdPrefersNewer() throws {
        let id = UUID()
        let older = try enc.encode([Item(id: id, name: "old")])
        let newer = try enc.encode([Item(id: id, name: "new")])

        let merge = KeyValueMergeRegistry.arrayMerge(Item.self)
        let merged = try dec.decode([Item].self, from: merge([older, newer]))

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged.first?.name, "new")
    }

    /// 字典型：union of keys，相同 key 取較新值
    func testDictUnionOfKeys() throws {
        let older = try enc.encode(["d1": 1, "shared": 10])
        let newer = try enc.encode(["d2": 2, "shared": 20])

        let merge = KeyValueMergeRegistry.dictMerge(Int.self)
        let merged = try dec.decode([String: Int].self, from: merge([older, newer]))

        XCTAssertEqual(merged, ["d1": 1, "d2": 2, "shared": 20])
    }

    /// 安全性：blob 解碼失敗 → 退回最新一包，絕不產生空集合或覆蓋資料
    func testArrayDecodeFailureFallsBackToNewest() throws {
        let valid = try enc.encode([Item(id: UUID(), name: "keep")])
        let garbage = Data("not json".utf8)

        let merge = KeyValueMergeRegistry.arrayMerge(Item.self)

        // 最新一包是壞資料 → 退回最新（等同原本 LWW），不會清空
        XCTAssertEqual(merge([valid, garbage]), garbage)
        // 舊的是壞資料、最新合法 → 退回最新合法包
        XCTAssertEqual(merge([garbage, valid]), valid)
    }

    /// 單一筆（無衝突）→ resolvedData 應原樣回傳，不動到資料
    func testResolvedDataSingleRecordUnchanged() throws {
        // 這裡只驗證 merge 函式對單包的行為：回傳該包
        let only = try enc.encode([Item(id: UUID(), name: "solo")])
        let merge = KeyValueMergeRegistry.arrayMerge(Item.self)
        let merged = try dec.decode([Item].self, from: merge([only]))
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged.first?.name, "solo")
    }
}
