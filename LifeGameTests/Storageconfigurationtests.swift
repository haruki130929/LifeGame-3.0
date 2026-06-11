import XCTest
@testable import LifeGame

/// StorageConfiguration 的測試
///
/// 這組測試檢查「儲存模式」(本機 / iCloud) 的設定邏輯是否正確。
/// 重點:每個測試都用一個「測試專用、乾淨的」UserDefaults,
/// 不會碰到 App 真正的設定,所以可以放心反覆執行。
final class StorageConfigurationTests: XCTestCase {

    /// 測試專用的 UserDefaults,每次測試前都會清空
    private var testDefaults: UserDefaults!
    private let suiteName = "test.lifegame.storageconfig"

    override func setUp() {
        super.setUp()
        // 建立一個獨立命名空間的 UserDefaults,跟真實資料完全隔離
        testDefaults = UserDefaults(suiteName: suiteName)
        // 清空,確保每個測試都從乾淨狀態開始
        testDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        // 測試結束後清掉,不留垃圾
        testDefaults.removePersistentDomain(forName: suiteName)
        testDefaults = nil
        super.tearDown()
    }

    // MARK: - setMode

    /// 設定模式後,currentMode 應該要跟著改變
    func test_設定模式_currentMode會更新() {
        // 安排
        let config = StorageConfiguration(defaults: testDefaults)

        // 執行
        config.setMode(.local)

        // 驗證
        XCTAssertEqual(config.currentMode, .local, "設成 local 後,currentMode 應該是 local")
    }

    // MARK: - Pending mode

    /// 排程一個待切換的模式,pendingMode 應該被記錄下來
    func test_排程待切換模式_pendingMode會被記錄() {
        // 安排
        let config = StorageConfiguration(defaults: testDefaults)
        config.setMode(.local)

        // 執行:排程切換到 iCloud
        config.setPendingMode(.iCloud)

        // 驗證
        XCTAssertEqual(config.pendingMode, .iCloud, "排程後 pendingMode 應該是 iCloud")
        XCTAssertEqual(config.currentMode, .local, "排程不應該立刻改變 currentMode")
    }

    /// 清除待切換模式後,pendingMode 應該變回 nil
    func test_清除待切換模式_pendingMode變回nil() {
        // 安排
        let config = StorageConfiguration(defaults: testDefaults)
        config.setPendingMode(.iCloud)

        // 執行
        config.clearPendingMode()

        // 驗證
        XCTAssertNil(config.pendingMode, "清除後 pendingMode 應該是 nil")
    }

    /// 確認切換:pending 應該變成 current,而且 pending 被清掉
    func test_確認切換_pending變成current() {
        // 安排
        let config = StorageConfiguration(defaults: testDefaults)
        config.setMode(.local)
        config.setPendingMode(.iCloud)

        // 執行
        config.confirmModeSwitch()

        // 驗證
        XCTAssertEqual(config.currentMode, .iCloud, "確認後 currentMode 應該變成原本 pending 的 iCloud")
        XCTAssertNil(config.pendingMode, "確認後 pendingMode 應該被清空")
    }

    /// 沒有 pending 時呼叫 confirm,不應該改變任何東西
    func test_沒有pending時確認切換_不改變current() {
        // 安排
        let config = StorageConfiguration(defaults: testDefaults)
        config.setMode(.local)

        // 執行:沒有 pending 的情況下呼叫
        config.confirmModeSwitch()

        // 驗證
        XCTAssertEqual(config.currentMode, .local, "沒有 pending 時不應改變 currentMode")
        XCTAssertNil(config.pendingMode)
    }

    /// 設定會持久化:用同一個 UserDefaults 建立新的 config,應該讀到之前存的模式
    func test_模式設定會持久化() {
        // 安排:第一個 config 設成 local
        let config1 = StorageConfiguration(defaults: testDefaults)
        config1.setMode(.local)

        // 執行:用「同一個」UserDefaults 建立新的 config(模擬 App 重啟)
        let config2 = StorageConfiguration(defaults: testDefaults)

        // 驗證:新的 config 應該讀到之前存的 local
        XCTAssertEqual(config2.currentMode, .local, "重新建立後應讀到之前持久化的模式")
    }
}
