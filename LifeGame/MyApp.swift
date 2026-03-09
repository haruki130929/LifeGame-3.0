import SwiftUI
import SwiftData

@main
struct LifeGameApp: App {
    // MARK: - 新的統一儲存層
    @State private var coordinator: StorageCoordinator
    @State private var storageConfig: StorageConfiguration
    @State private var keyValueStore: KeyValueStore

    // MARK: - 既有的 Store（保持不動）
    @StateObject private var theme = ThemeStore()
    @StateObject private var calendarStore = CalendarStore()
    @StateObject private var calendarSettings = CalendarSettingsStore()
    @StateObject private var fab = FabStore()
    @StateObject private var wishStore = WishStore()
    @StateObject private var ledgerStore = LedgerStore()
    @StateObject private var moodHistory = MoodHistoryStore()

    init() {
        // 1. 註冊所有 @Model 類型
        StorageCoordinator.registerModelType(DailyLogRecord.self)

        // 2. 讀取儲存模式偏好
        let config = StorageConfiguration()

        // 3. 建立 StorageCoordinator
        let coord: StorageCoordinator
        do {
            coord = try StorageCoordinator(configuration: config)
        } catch {
            fatalError("無法初始化儲存系統：\(error.localizedDescription)")
        }

        // 4. 讓舊版 StorageManager 也使用新的容器
        StorageManager.coordinator = coord

        // 5. 建立 KeyValueStore
        let kvStore = KeyValueStore { coord.mainContext }

        _coordinator = State(initialValue: coord)
        _storageConfig = State(initialValue: config)
        _keyValueStore = State(initialValue: kvStore)
    }

    var body: some Scene {
        WindowGroup {
            HomeRootContainerView()
                // 新的儲存層
                .environment(coordinator)
                .environment(storageConfig)
                .environment(keyValueStore)
                // 既有的 Store
                .environmentObject(theme)
                .environmentObject(calendarStore)
                .environmentObject(calendarSettings)
                .environmentObject(fab)
                .environmentObject(wishStore)
                .environmentObject(ledgerStore)
                .environmentObject(moodHistory)
                .id(storageConfig.currentMode)
        }
        .modelContainer(coordinator.modelContainer)
    }
}
