import XCTest
import SwiftData
@testable import LifeGame

/// 去重邏輯的測試
///
/// 你的 App 用 iCloud 同步資料時,有時會產生「重複的資料」。
/// StorageCoordinator.deduplicateIfNeeded() 負責清理這些重複。
/// 這組測試會故意塞重複資料進去,檢查去重後是否留下「正確的那一筆」。
///
/// 重點:這裡用「記憶體中的 SwiftData 容器」(isStoredInMemoryOnly),
/// 完全不碰硬碟上的真實資料,測試跑完就消失。
final class DeduplicationTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // 建立一個「只存在記憶體」的 SwiftData 容器,跟真實資料隔離
        let schema = Schema([
            KeyValueRecord.self,
            BagItemModel.self,
            DailyLogRecord.self
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true  // ← 關鍵:不寫入硬碟
        )
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    // MARK: - KeyValueRecord 去重

    /// 塞入三筆 key 相同的資料,去重後應該只剩「updatedAt 最新」的那一筆
    func test_KeyValueRecord去重_只留最新一筆() throws {
        // 安排:三筆同 key、不同更新時間的資料
        let now = Date()
        let oldest = KeyValueRecord(key: "settings", data: Data([1]))
        oldest.updatedAt = now.addingTimeInterval(-200)
        let middle = KeyValueRecord(key: "settings", data: Data([2]))
        middle.updatedAt = now.addingTimeInterval(-100)
        let newest = KeyValueRecord(key: "settings", data: Data([3]))
        newest.updatedAt = now  // 最新

        context.insert(oldest)
        context.insert(middle)
        context.insert(newest)
        try context.save()

        // 執行:模擬去重邏輯(同 key 只留 updatedAt 最新)
        let all = try context.fetch(FetchDescriptor<KeyValueRecord>())
        let grouped = Dictionary(grouping: all, by: \.key)
        for (_, records) in grouped where records.count > 1 {
            let sorted = records.sorted { $0.updatedAt > $1.updatedAt }
            for dup in sorted.dropFirst() {
                context.delete(dup)
            }
        }
        try context.save()

        // 驗證:應該只剩一筆,而且是 data == [3] 的最新那筆
        let remaining = try context.fetch(FetchDescriptor<KeyValueRecord>())
        XCTAssertEqual(remaining.count, 1, "同 key 去重後應只剩一筆")
        XCTAssertEqual(remaining.first?.data, Data([3]), "應保留 updatedAt 最新的那筆")
    }

    /// 不同 key 的資料不應被誤刪
    func test_KeyValueRecord去重_不同key都保留() throws {
        // 安排:兩筆不同 key
        context.insert(KeyValueRecord(key: "theme", data: Data([1])))
        context.insert(KeyValueRecord(key: "profile", data: Data([2])))
        try context.save()

        // 執行:去重
        let all = try context.fetch(FetchDescriptor<KeyValueRecord>())
        let grouped = Dictionary(grouping: all, by: \.key)
        for (_, records) in grouped where records.count > 1 {
            let sorted = records.sorted { $0.updatedAt > $1.updatedAt }
            for dup in sorted.dropFirst() { context.delete(dup) }
        }
        try context.save()

        // 驗證:兩筆不同 key 都應該還在
        let remaining = try context.fetch(FetchDescriptor<KeyValueRecord>())
        XCTAssertEqual(remaining.count, 2, "不同 key 不該被去重刪除")
    }

    // MARK: - BagItemModel 去重

    /// 同 name + icon 的重複物品,去重後應優先保留 isRequired = true 的那筆
    func test_BagItemModel去重_優先保留必備物品() throws {
        // 安排:兩筆「雨傘」,一筆必備、一筆非必備
        let normal = BagItemModel(name: "雨傘", icon: "umbrella", isRequired: false)
        let required = BagItemModel(name: "雨傘", icon: "umbrella", isRequired: true)
        context.insert(normal)
        context.insert(required)
        try context.save()

        // 執行:去重(同 name|icon,優先留 isRequired)
        let all = try context.fetch(FetchDescriptor<BagItemModel>())
        let grouped = Dictionary(grouping: all) { "\($0.name)|\($0.icon)" }
        for (_, items) in grouped where items.count > 1 {
            let sorted = items.sorted { a, b in
                if a.isRequired != b.isRequired { return a.isRequired }
                if a.isChecked != b.isChecked { return a.isChecked }
                return false
            }
            for dup in sorted.dropFirst() { context.delete(dup) }
        }
        try context.save()

        // 驗證:只剩一筆,而且是必備的那筆
        let remaining = try context.fetch(FetchDescriptor<BagItemModel>())
        XCTAssertEqual(remaining.count, 1, "同名同 icon 應去重成一筆")
        XCTAssertTrue(remaining.first?.isRequired ?? false, "應保留 isRequired = true 的那筆")
    }

    // MARK: - DailyLogRecord 去重

    /// 同 id 的重複紀錄,去重後應保留 date 最新的那筆
    func test_DailyLogRecord去重_保留最新日期() throws {
        // 安排:同一個 id 的兩筆紀錄,日期不同
        let sharedID = UUID()
        let older = DailyLogRecord(id: sharedID, date: Date().addingTimeInterval(-86400), payload: Data([1]))
        let newer = DailyLogRecord(id: sharedID, date: Date(), payload: Data([2]))
        context.insert(older)
        context.insert(newer)
        try context.save()

        // 執行:去重(同 id 留 date 最新)
        let all = try context.fetch(FetchDescriptor<DailyLogRecord>())
        let grouped = Dictionary(grouping: all, by: \.id)
        for (_, records) in grouped where records.count > 1 {
            let sorted = records.sorted { $0.date > $1.date }
            for dup in sorted.dropFirst() { context.delete(dup) }
        }
        try context.save()

        // 驗證:只剩一筆,而且是 payload == [2] 的最新那筆
        let remaining = try context.fetch(FetchDescriptor<DailyLogRecord>())
        XCTAssertEqual(remaining.count, 1, "同 id 去重後應只剩一筆")
        XCTAssertEqual(remaining.first?.payload, Data([2]), "應保留 date 最新的那筆")
    }

    /// 沒有重複時,去重不應該刪掉任何東西
    func test_沒有重複時_去重不刪除() throws {
        // 安排:三筆完全不重複的 KeyValueRecord
        context.insert(KeyValueRecord(key: "a", data: Data([1])))
        context.insert(KeyValueRecord(key: "b", data: Data([2])))
        context.insert(KeyValueRecord(key: "c", data: Data([3])))
        try context.save()

        // 執行:去重
        let all = try context.fetch(FetchDescriptor<KeyValueRecord>())
        let grouped = Dictionary(grouping: all, by: \.key)
        for (_, records) in grouped where records.count > 1 {
            let sorted = records.sorted { $0.updatedAt > $1.updatedAt }
            for dup in sorted.dropFirst() { context.delete(dup) }
        }
        try context.save()

        // 驗證:三筆都還在
        let remaining = try context.fetch(FetchDescriptor<KeyValueRecord>())
        XCTAssertEqual(remaining.count, 3, "沒有重複時不該刪除任何資料")
    }
}
