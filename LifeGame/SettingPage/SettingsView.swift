import SwiftUI
import MessageUI
import AuthenticationServices

struct SettingsView: View {

    @EnvironmentObject private var fab: FabStore
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var updateChecker: AppUpdateChecker
    @EnvironmentObject private var calendarSettings: CalendarSettingsStore
    @EnvironmentObject private var ringSettings: TomorrowRingSettingsStore
    @EnvironmentObject private var phoneModeStore: PhoneModeStore
    @EnvironmentObject private var slotNameStore: TimeSlotNameStore
    @EnvironmentObject private var appleSignIn: AppleSignInManager
    @Environment(StorageCoordinator.self) private var coordinator: StorageCoordinator?

    // MARK: - 通知
    @State private var hourlyMoodEnabled: Bool = false
    private let hourlyMoodEnabledKey = "hourlyMoodReminderEnabled_v1"

    // MARK: - 回饋
    @State private var showFeedbackMail = false
    @State private var showMailUnavailable = false

    var body: some View {
        Form {
            if !AppLayout.isIPad {
                phoneModeSection
            }
            if !AppLayout.isIPad {
                interfaceSection
            }
            roleSection
            notificationSection
            dailyLogSection
            featureSection
            widgetSection
            appearanceSection
            accountSection
            storageSection
            feedbackSection
            updateSection
            aboutSection
        }
        .navigationTitle(L10n.Title.settings)
        .onAppear {
            hourlyMoodEnabled = StorageManager.load(Bool.self, forKey: hourlyMoodEnabledKey) ?? false
            fab.isHidden = true
        }
        .onDisappear {
            fab.isHidden = false
        }
        .sheet(isPresented: $showFeedbackMail) {
            FeedbackMailView()
        }
        .alert("無法傳送郵件", isPresented: $showMailUnavailable) {
            Button("複製信箱地址") {
                UIPasteboard.general.string = "harukiyang122@gmail.com"
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("你的裝置尚未設定郵件帳號。\n請手動寄信至 harukiyang122@gmail.com")
        }
    }
}

// MARK: - Sections
private extension SettingsView {

    // MARK: 顯示模式
    var phoneModeSection: some View {
        Section {
            Picker("顯示模式", selection: $phoneModeStore.mode) {
                Text("一般模式").tag(PhoneMode.full)
                Text("簡略模式").tag(PhoneMode.quick)
            }
            .pickerStyle(.segmented)

            if phoneModeStore.mode == .quick {
                NavigationLink {
                    QuickPageConfigView()
                } label: {
                    Label("編輯快速頁面", systemImage: "rectangle.stack")
                }
            }
        } header: {
            Text("顯示模式")
        } footer: {
            Text(phoneModeStore.mode == .quick
                 ? "簡略模式：左右滑動切換功能頁面"
                 : "一般模式：與 iPad 相同的完整功能")
        }
    }

    // MARK: 介面操作
    var interfaceSection: some View {
        Section("介面操作") {
            NavigationLink {
                InterfaceSettingsView()
            } label: {
                Label("「＋」按鈕操作方式", systemImage: "hand.tap")
            }
        }
    }

    // MARK: 身份設定
    var roleSection: some View {
        Section("身份設定") {
            Picker(selection: $slotNameStore.role) {
                ForEach(UserRole.allCases) { role in
                    Text(role.displayName).tag(role)
                }
            } label: {
                Label("我的身份", systemImage: slotNameStore.role == .student ? "graduationcap.fill" : "briefcase.fill")
            }

            NavigationLink {
                TimeSlotTimeSettingsView()
            } label: {
                Label("時段時間", systemImage: "clock")
            }
        }
    }

    // MARK: 通知
    var notificationSection: some View {
        Section {
            Toggle("每小時提醒記錄心情", isOn: $hourlyMoodEnabled)
                .onChange(of: hourlyMoodEnabled) { _, newValue in
                    applyNotificationChange(newValue)
                }
        } header: {
            Text("通知")
        } footer: {
            Text("開啟後每小時會提醒你記錄心情溫度")
        }
    }

    // MARK: 每日紀錄
    var dailyLogSection: some View {
        Section("每日紀錄") {
            NavigationLink {
                QuestionModuleSettingsView()
            } label: {
                Label("問題模組管理", systemImage: "list.bullet.rectangle")
            }
        }
    }

    // MARK: 功能設定
    var featureSection: some View {
        Section(L10n.Settings.featureSettings) {
            NavigationLink {
                CalendarSettingsView(settings: calendarSettings)
            } label: {
                Label(L10n.Title.calendar, systemImage: "calendar")
            }
            NavigationLink {
                TodoQuadrantSettingsView()
            } label: {
                Label(L10n.Title.todoQuadrant, systemImage: "list.bullet.clipboard")
            }
            NavigationLink {
                TomorrowRingSettingsView(settings: ringSettings)
            } label: {
                Label(L10n.Title.tomorrowRing, systemImage: "clock")
            }
            NavigationLink {
                MonthlyScoreSettingsView()
            } label: {
                Label(L10n.Title.monthlyScore, systemImage: "calendar.badge.clock")
            }
            NavigationLink {
                BagSettingsView()
            } label: {
                Label(L10n.Title.bagRequired, systemImage: "backpack")
            }
            NavigationLink {
                MoodSettingsView()
            } label: {
                Label(L10n.Title.moodThermometer, systemImage: "heart.text.square")
            }
            NavigationLink {
                MandalaSettingsView()
            } label: {
                Label(L10n.Title.mandala, systemImage: "square.grid.3x3")
            }
        }
    }

    // MARK: 桌面工具（獨立一欄）
    var widgetSection: some View {
        Section {
            NavigationLink {
                WidgetSettingsView()
            } label: {
                Label("桌面工具", systemImage: "square.grid.2x2")
            }
        }
    }

    // MARK: 外觀設定
    var appearanceSection: some View {
        Section(L10n.Settings.appearance) {
            NavigationLink {
                AppearanceSettingsView()
            } label: {
                Label(L10n.Title.themeSettings, systemImage: "paintbrush")
            }
        }
    }

    // MARK: 帳號
    var accountSection: some View {
        Section {
            if appleSignIn.isSignedIn {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(theme.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appleSignIn.displayName)
                            .font(.body.weight(.medium))
                        Text("已透過 Apple ID 登入")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } else {
                VStack(spacing: 12) {
                    Text("登入 Apple ID 以同步資料")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        appleSignIn.handleSignInResult(result)
                        if appleSignIn.isSignedIn {
                            coordinator?.scheduleSwitch(to: .iCloud)
                        }
                    }
                    .signInWithAppleButtonStyle(theme.isDark ? .white : .black)
                    .frame(height: 44)
                }
            }
        } header: {
            Text("帳號")
        } footer: {
            if appleSignIn.isSignedIn {
                Text("資料會自動同步到 iCloud，刪除 App 重裝後資料會自動恢復")
            }
        }
    }

    // MARK: 資料儲存
    var storageSection: some View {
        Section(L10n.Settings.dataStorage) {
            NavigationLink {
                StorageSettingsView()
            } label: {
                Label(L10n.Settings.storageMethod, systemImage: "externaldrive.fill.badge.icloud")
            }
            NavigationLink {
                BackupSettingsView()
            } label: {
                Label(L10n.Title.backupSettings, systemImage: "arrow.triangle.2.circlepath")
            }
        }
    }

    // MARK: 使用者回饋
    var feedbackSection: some View {
        Section {
            Button {
                if MFMailComposeViewController.canSendMail() {
                    showFeedbackMail = true
                } else {
                    showMailUnavailable = true
                }
            } label: {
                Label("分享使用體驗", systemImage: "envelope")
                    .foregroundStyle(theme.isDark ? .white : Color(.label))
            }
        } header: {
            Text(L10n.Settings.feedback)
        } footer: {
            Text("告訴我你的使用體驗、建議或遇到的問題")
        }
    }

    // MARK: 版本更新
    var updateSection: some View {
        Section {
            Button {
                updateChecker.openAppStore()
            } label: {
                HStack {
                    Label("版本更新", systemImage: "arrow.down.app")
                        .foregroundStyle(theme.isDark ? .white : Color(.label))
                    Spacer()
                    if updateChecker.hasUpdate, let version = updateChecker.latestVersion {
                        Text("v\(version) 可更新")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("已是最新版本")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if updateChecker.hasUpdate {
                        Circle()
                            .fill(.red)
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
    }

    // MARK: 關於
    var aboutSection: some View {
        Section(L10n.Settings.about) {
            HStack {
                Text(L10n.Settings.version)
                Spacer()
                Text(appVersionString)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text(L10n.Settings.developer)
                Spacer()
                Text("はるき")
                    .foregroundStyle(.secondary)
            }
        }
    }

    var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}

// MARK: - Notification helpers
private extension SettingsView {

    func applyNotificationChange(_ enabled: Bool) {
        StorageManager.save(enabled, forKey: hourlyMoodEnabledKey)

        if enabled {
            NotificationManager.requestPermissionIfNeeded { granted in
                DispatchQueue.main.async {
                    if granted {
                        NotificationManager.scheduleHourlyMoodReminder(minute: 0)
                    } else {
                        StorageManager.save(false, forKey: hourlyMoodEnabledKey)
                        hourlyMoodEnabled = false
                    }
                }
            }
        } else {
            NotificationManager.cancelHourlyMoodReminder()
        }
    }
}
