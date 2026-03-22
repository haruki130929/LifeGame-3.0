import SwiftUI
import MessageUI

struct SettingsView: View {

    @EnvironmentObject private var fab: FabStore
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var updateChecker: AppUpdateChecker
    @EnvironmentObject private var calendarSettings: CalendarSettingsStore
    @EnvironmentObject private var ringSettings: TomorrowRingSettingsStore
    @EnvironmentObject private var phoneModeStore: PhoneModeStore

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
            notificationSection
            dailyLogSection
            featureSection
            appearanceSection
            storageSection
            feedbackSection
            updateSection
            aboutSection
        }
        .navigationTitle("設定")
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
        Section("功能設定") {
            NavigationLink {
                CalendarSettingsView(settings: calendarSettings)
            } label: {
                Label("行事曆", systemImage: "calendar")
            }
            NavigationLink {
                TodoQuadrantSettingsView()
            } label: {
                Label("待辦四象限", systemImage: "list.bullet.clipboard")
            }
            NavigationLink {
                TomorrowRingSettingsView(settings: ringSettings)
            } label: {
                Label("時間圓環", systemImage: "clock")
            }
            NavigationLink {
                MonthlyScoreSettingsView()
            } label: {
                Label("本月結算", systemImage: "calendar.badge.clock")
            }
            NavigationLink {
                BagSettingsView()
            } label: {
                Label("整理書包", systemImage: "backpack")
            }
            NavigationLink {
                MoodSettingsView()
            } label: {
                Label("心情溫度計", systemImage: "heart.text.square")
            }
            NavigationLink {
                MandalaSettingsView()
            } label: {
                Label("曼陀羅圖表", systemImage: "square.grid.3x3")
            }
        }
    }

    // MARK: 外觀設定
    var appearanceSection: some View {
        Section("外觀設定") {
            NavigationLink {
                AppearanceSettingsView()
            } label: {
                Label("主題與配色", systemImage: "paintbrush")
            }
        }
    }

    // MARK: 資料儲存
    var storageSection: some View {
        Section("資料儲存") {
            NavigationLink {
                StorageSettingsView()
            } label: {
                Label("儲存方式", systemImage: "externaldrive.fill.badge.icloud")
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
            Text("意見回饋")
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
        Section("關於") {
            HStack {
                Text("版本")
                Spacer()
                Text(appVersionString)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("開發者")
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
