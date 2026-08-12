import SwiftUI
import SwiftData
import UserNotifications

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
    @StateObject private var aquariumStore = AquariumStore()
    @StateObject private var phoneModeStore = PhoneModeStore()
    @StateObject private var coachMarkStore = CoachMarkStore()
    @StateObject private var slotNameStore = TimeSlotNameStore()
    @StateObject private var slotTimeStore = TimeSlotTimeStore()
    @StateObject private var homeNavigator = HomeNavigator()
    @StateObject private var appleSignIn = AppleSignInManager()
    @StateObject private var languageStore = LanguageStore()
    @State private var tutorialTracker = FeatureTutorialTracker()

    // NOTE: 以下 Store 已移至 HomeRootContainerView（功能頁面層級）：
    // calendarSettings, moodHistory, ringSettings, moduleStore,
    // historyStore, moodSettings, mandalaStore, todoStore,
    // updateChecker, characterStore

    init() {
        // 1. 註冊所有 @Model 類型
        StorageCoordinator.registerModelType(DailyLogRecord.self)
        StorageCoordinator.registerModelType(BagItemModel.self)

        // 1b. 註冊各集合型 store 的同步合併策略（須在任何去重/載入之前）
        SyncMergeRegistration.registerAll()

        // 1c. 在地化：記錄本次啟動實際生效的語言，並確認 String(localized:) 的遮蔽有生效
        AppLocalization.bootstrap()
        AppLocalization.verifyShadowingWorks()

        // 2. 讀取儲存模式偏好
        let config = StorageConfiguration()

        // 3. 嘗試建立 StorageCoordinator（兩次機會）
        var coord: StorageCoordinator?
        var errorMessage: String?

        do {
            coord = try StorageCoordinator(configuration: config)
        } catch {
            debugLog("⚠️ 第一次初始化失敗，暫時使用本機模式重試：\(error)")
            // 只清除 pending，不永久改變儲存模式（下次啟動仍會嘗試 iCloud）
            config.clearPendingMode()
            let savedMode = config.currentMode
            config.setMode(.local)
            do {
                coord = try StorageCoordinator(configuration: config)
                // 恢復原本的模式設定，讓下次啟動再嘗試
                config.setMode(savedMode)
                debugLog("ℹ️ 已暫時降級到本機模式，下次啟動會重新嘗試 \(savedMode)")
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

        // 互動通知：掛上 delegate 並註冊動作分類（待辦「完成」、心情輸入 0–10）。
        // 註：先前 delegate 從未被指派，所以前景顯示與動作回呼都不會觸發 —— 一併修正。
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        NotificationManager.setupNotificationCategories()

        // 使用者在設定頁換了語言並重新啟動後，把重複性通知改用新語言重排一次
        NotificationManager.refreshLocalizedRemindersIfLanguageChanged()
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
                        .environmentObject(aquariumStore)
                        .environmentObject(phoneModeStore)
                        .environmentObject(coachMarkStore)
                        .environmentObject(slotNameStore)
                        .environmentObject(slotTimeStore)
                        .environmentObject(homeNavigator)
                        .environmentObject(appleSignIn)
                        .environmentObject(languageStore)
                        .environment(tutorialTracker)
                        // 語言即時切換：Text(LocalizedStringKey) 吃 environment locale，
                        // 而 .id() 讓語言一變就整棵重建，把已算好的畫面重新以新語言渲染。
                        .environment(\.locale, languageStore.environmentLocale)
                        // SwiftData 容器（只在 coordinator 可用時掛載）
                        .modelContainer(coordinator.modelContainer)
                        .id(storageConfig.currentMode)
                        // ✅ Window 層級再套一次，確保整個視窗（狀態列等）都切換深淺模式
                        .preferredColorScheme(theme.appearance.preferredColorScheme)
                        // Mac Catalyst：設定視窗最小尺寸（其他平台 no-op）
                        .macWindowMinSize(width: 960, height: 680)
                        // 版本更新內容
                        .onAppear {
                            coordinator.deduplicateIfNeeded()
                            coordinator.diagnoseiCloudSync()
                            if VersionTracker.shouldShowWhatsNew {
                                showWhatsNew = true
                            }
                        }
                        .sheet(isPresented: $showWhatsNew) {
                            WhatsNewView(version: VersionTracker.currentVersion) {
                                VersionTracker.markAsShown()
                                showWhatsNew = false
                            }
                            .environmentObject(theme)
                            .interactiveDismissDisabled()
                        }
                        .overlay { ToastOverlay() }
                        .onChange(of: scenePhase) { _, phase in
                            if phase == .active {
                                WatchChangeObserver.shared.checkForWatchChanges()
                                LiveActivityController.reconcile()
                                TodoLiveActivityController.reconcile()
                            }
                        }
                } else {
                    OnboardingView(completed: $onboardingCompleted)
                        .environment(coordinator)
                        .environment(storageConfig)
                        .environmentObject(theme)
                        .environmentObject(phoneModeStore)
                        .environmentObject(slotNameStore)
                        .environmentObject(slotTimeStore)
                        .environmentObject(appleSignIn)
                        .environmentObject(languageStore)
                        .environment(tutorialTracker)
                        .environment(\.locale, languageStore.environmentLocale)
                        .preferredColorScheme(theme.appearance.preferredColorScheme)
                }
            } else {
                StorageErrorView(
                    errorMessage: startupError ?? String(localized: "未知錯誤"),
                    onRetry: retryInitialization
                )
            }
        }
        #if targetEnvironment(macCatalyst)
        // Mac 選單列快捷鍵（其他平台不套用，維持 iPhone/iPad 行為不變）
        .commands {
            // 用 App 內的設定頁取代預設的「偏好設定…」選項（⌘,）
            CommandGroup(replacing: .appSettings) {
                Button("偏好設定…") { homeNavigator.go(to: .settings) }
                    .keyboardShortcut(",", modifiers: .command)
            }
            CommandMenu("導覽") {
                Button("回到主頁") { homeNavigator.popToRoot() }
                    .keyboardShortcut("0", modifiers: .command)
                Button("快速動作選單") { fab.requestToggle() }
                    .keyboardShortcut("k", modifiers: .command)
            }
        }
        #endif
    }

    // MARK: - Retry

    private func retryInitialization() {
        let config = StorageConfiguration()
        config.clearPendingMode()
        let savedMode = config.currentMode
        config.setMode(.local)

        do {
            let coord = try StorageCoordinator(configuration: config)
            StorageManager.coordinator = coord

            self.coordinator = coord
            self.storageConfig = config
            self.keyValueStore = KeyValueStore { coord.mainContext }
            self.startupError = nil
            // 恢復原本的模式設定，讓下次啟動再嘗試
            config.setMode(savedMode)
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
