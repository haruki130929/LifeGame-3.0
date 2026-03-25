import SwiftUI
import SwiftData

@main
struct LifeGameApp: App {
    // MARK: - 新的統一儲存層
    @State private var coordinator: StorageCoordinator?
    @State private var storageConfig: StorageConfiguration
    @State private var keyValueStore: KeyValueStore?
    @State private var startupError: String?

    // MARK: - 全域 Store（跨功能或 Onboarding 時需要）
    @StateObject private var theme = ThemeStore()
    @StateObject private var calendarStore = CalendarStore()
    @StateObject private var fab = FabStore()
    @StateObject private var wishStore = WishStore()
    @StateObject private var ledgerStore = LedgerStore()
    @StateObject private var phoneModeStore = PhoneModeStore()
    @StateObject private var coachMarkStore = CoachMarkStore()
    @StateObject private var slotNameStore = TimeSlotNameStore()
    @StateObject private var appleSignIn = AppleSignInManager()
    @StateObject private var tutorialTracker = FeatureTutorialTracker()

    // NOTE: 以下 Store 已移至 HomeRootContainerView（功能頁面層級）：
    // calendarSettings, moodHistory, ringSettings, moduleStore,
    // historyStore, moodSettings, mandalaStore, todoStore,
    // updateChecker, characterStore

    init() {
        // 1. 註冊所有 @Model 類型
        StorageCoordinator.registerModelType(DailyLogRecord.self)
        StorageCoordinator.registerModelType(BagItemModel.self)

        // 2. 讀取儲存模式偏好
        let config = StorageConfiguration()

        // 3. 嘗試建立 StorageCoordinator（兩次機會）
        var coord: StorageCoordinator?
        var errorMessage: String?

        do {
            coord = try StorageCoordinator(configuration: config)
        } catch {
            debugLog("⚠️ 第一次初始化失敗，重置為本機模式重試：\(error)")
            // 只清除 pending，不改 currentMode（讓 StorageCoordinator 內部處理回退）
            config.clearPendingMode()
            config.setMode(.local)
            do {
                coord = try StorageCoordinator(configuration: config)
            } catch {
                debugLog("❌ 儲存系統無法初始化：\(error)")
                errorMessage = error.localizedDescription
            }
        }

        // 4. 設定舊版 StorageManager + KeyValueStore
        if let coord {
            StorageManager.coordinator = coord
        }

        let kvStore: KeyValueStore? = coord.map { c in
            KeyValueStore { c.mainContext }
        }

        _coordinator = State(initialValue: coord)
        _storageConfig = State(initialValue: config)
        _keyValueStore = State(initialValue: kvStore)
        _startupError = State(initialValue: errorMessage)
    }

    @State private var onboardingCompleted = OnboardingTracker.isCompleted
    @State private var showWhatsNew = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if let coordinator, let keyValueStore, startupError == nil {
                if onboardingCompleted {
                    HomeRootContainerView()
                        // 新的儲存層
                        .environment(coordinator)
                        .environment(storageConfig)
                        .environment(keyValueStore)
                        // 主題套用（tint / colorScheme / dynamicType）
                        .applyTheme()
                        // 全域 Store（功能頁專用的已移至 HomeRootContainerView）
                        .environmentObject(theme)
                        .environmentObject(calendarStore)
                        .environmentObject(fab)
                        .environmentObject(wishStore)
                        .environmentObject(ledgerStore)
                        .environmentObject(phoneModeStore)
                        .environmentObject(coachMarkStore)
                        .environmentObject(slotNameStore)
                        .environmentObject(appleSignIn)
                        .environmentObject(tutorialTracker)
                        // SwiftData 容器（只在 coordinator 可用時掛載）
                        .modelContainer(coordinator.modelContainer)
                        .id(storageConfig.currentMode)
                        // ✅ Window 層級再套一次，確保整個視窗（狀態列等）都切換深淺模式
                        .preferredColorScheme(theme.appearance.preferredColorScheme)
                        // 版本更新內容
                        .onAppear {
                            if VersionTracker.shouldShowWhatsNew {
                                showWhatsNew = true
                            }
                        }
                        .sheet(isPresented: $showWhatsNew) {
                            WhatsNewView(version: VersionTracker.currentVersion) {
                                VersionTracker.markAsShown()
                                showWhatsNew = false
                            }
                            .interactiveDismissDisabled()
                        }
                        .overlay { ToastOverlay() }
                        .onChange(of: scenePhase) { _, phase in
                            if phase == .active {
                                WatchChangeObserver.shared.checkForWatchChanges()
                            }
                        }
                } else {
                    OnboardingView(completed: $onboardingCompleted)
                        .environment(coordinator)
                        .environment(storageConfig)
                        .environmentObject(theme)
                        .environmentObject(phoneModeStore)
                        .environmentObject(slotNameStore)
                        .environmentObject(appleSignIn)
                        .environmentObject(tutorialTracker)
                        .preferredColorScheme(theme.appearance.preferredColorScheme)
                }
            } else {
                StorageErrorView(
                    errorMessage: startupError ?? "未知錯誤",
                    onRetry: retryInitialization
                )
            }
        }
    }

    // MARK: - Retry

    private func retryInitialization() {
        let config = StorageConfiguration()
        config.clearPendingMode()
        config.setMode(.local)

        do {
            let coord = try StorageCoordinator(configuration: config)
            StorageManager.coordinator = coord

            self.coordinator = coord
            self.storageConfig = config
            self.keyValueStore = KeyValueStore { coord.mainContext }
            self.startupError = nil
        } catch {
            self.startupError = error.localizedDescription
        }
    }
}

// MARK: - 儲存錯誤畫面

private struct StorageErrorView: View {
    let errorMessage: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 56))
                .foregroundStyle(.red.opacity(0.7))

            Text("儲存系統無法啟動")
                .font(.title2.bold())

            Text(errorMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onRetry) {
                Label("重試", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            Text("如果問題持續，請嘗試重新啟動 App\n或檢查裝置儲存空間")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }
}
