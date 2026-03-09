import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject private var theme: ThemeStore
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Draft (草稿)
    @State private var draftFontScale: Double = 1.0
    @State private var draftBackgroundStyle: ThemeStore.BackgroundStyle = .system
    @State private var draftAccentPreset: ThemeStore.AccentPreset = .blue
    @State private var draftUseCustomAccent: Bool = false
    @State private var draftCustomAccentHex: String = ""
    @State private var draftAppearance: ThemeStore.AppAppearance = .system
    
    // MARK: - 通知（即時生效，不走 draft 模式）
    @State private var hourlyMoodEnabled: Bool = false
    private let hourlyMoodEnabledKey = "hourlyMoodReminderEnabled_v1"

    // MARK: - UI
    @State private var hasLoaded = false
    
    var body: some View {
        Form {
            storageSection
            notificationSection
            previewSection
            appearanceSection
            accentSection
            backgroundSection
            textSection
            aboutSection
        }
        .navigationTitle("設定")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("關閉") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") {
                    saveToTheme()
                    dismiss()
                }
                .disabled(!isDirty)
            }
        }
        .onAppear {
            guard !hasLoaded else { return }
            loadFromTheme()
            loadNotificationSettings()
            hasLoaded = true
        }
    }
}

// MARK: - Sections
private extension SettingsView {

    var storageSection: some View {
        Section("資料") {
            NavigationLink {
                StorageSettingsView()
            } label: {
                HStack {
                    Image(systemName: "externaldrive.fill.badge.icloud")
                        .foregroundStyle(.blue)
                    Text("儲存方式")
                }
            }
        }
    }

    var notificationSection: some View {
        Section {
            Toggle("每小時提醒記錄心情", isOn: $hourlyMoodEnabled)
                .onChange(of: hourlyMoodEnabled) { _, newValue in
                    StorageManager.save(newValue, forKey: hourlyMoodEnabledKey)

                    if newValue {
                        NotificationManager.requestPermissionIfNeeded { granted in
                            DispatchQueue.main.async {
                                if granted {
                                    NotificationManager.scheduleHourlyMoodReminder(minute: 0)
                                } else {
                                    hourlyMoodEnabled = false
                                    StorageManager.save(false, forKey: hourlyMoodEnabledKey)
                                }
                            }
                        }
                    } else {
                        NotificationManager.cancelHourlyMoodReminder()
                    }
                }
        } header: {
            Text("通知")
        } footer: {
            Text("開啟後每小時會提醒你記錄心情溫度（0～10）")
        }
    }

    var previewSection: some View {
        Section("預覽") {
            ThemePreviewCard(
                backgroundStyle: draftBackgroundStyle,
                accentColor: draftAccentColor,
                fontScale: draftFontScale,
                appearance: draftAppearance
            )
            .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
        }
    }
    
    var appearanceSection: some View {
        Section("外觀") {
            Picker("模式", selection: $draftAppearance) {
                ForEach(ThemeStore.AppAppearance.allCases) { a in
                    Text(a.title).tag(a)
                }
            }
        }
    }
    
    var accentSection: some View {
        Section("主色") {
            Picker("預設顏色", selection: $draftAccentPreset) {
                ForEach(ThemeStore.AccentPreset.allCases) { p in
                    HStack {
                        Circle().fill(p.color).frame(width: 10, height: 10)
                        Text(p.title)
                    }
                    .tag(p)
                }
            }
            
            Toggle("使用自訂色碼", isOn: $draftUseCustomAccent)
            
            if draftUseCustomAccent {
                TextField("Hex（例如 #FF8800 或 FF8800 或 F80）", text: $draftCustomAccentHex)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                HStack {
                    Text("目前色碼")
                    Spacer()
                    RoundedRectangle(cornerRadius: 8)
                        .fill(draftAccentColor)
                        .frame(width: 48, height: 22)
                }
            }
        }
    }
    
    var backgroundSection: some View {
        Section("背景") {
            Picker("背景樣式", selection: $draftBackgroundStyle) {
                ForEach(ThemeStore.BackgroundStyle.allCases) { s in
                    Text(s.title).tag(s)
                }
            }
        }
    }
    
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

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    var textSection: some View {
        Section("文字") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("字級倍率")
                    Spacer()
                    Text(String(format: "%.2f", draftFontScale))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $draftFontScale, in: 0.85...1.25, step: 0.05)
            }
            .padding(.vertical, 6)
        }
    }
}

// MARK: - Draft helpers
private extension SettingsView {
    
    func loadNotificationSettings() {
        if let v: Bool = StorageManager.load(Bool.self, forKey: hourlyMoodEnabledKey) {
            hourlyMoodEnabled = v
        }

        // 重開 app 時，如果開關是 on，補排一次避免系統清掉排程
        if hourlyMoodEnabled {
            NotificationManager.requestPermissionIfNeeded { granted in
                DispatchQueue.main.async {
                    if granted {
                        NotificationManager.scheduleHourlyMoodReminder(minute: 0)
                    } else {
                        hourlyMoodEnabled = false
                        StorageManager.save(false, forKey: hourlyMoodEnabledKey)
                    }
                }
            }
        }
    }

    func loadFromTheme() {
        draftFontScale = theme.fontScale
        draftBackgroundStyle = theme.backgroundStyle
        draftAccentPreset = theme.accentPreset
        draftUseCustomAccent = theme.useCustomAccent
        draftCustomAccentHex = theme.customAccentHex
        draftAppearance = theme.appearance
    }
    
    var isDirty: Bool {
        draftFontScale != theme.fontScale ||
        draftBackgroundStyle != theme.backgroundStyle ||
        draftAccentPreset != theme.accentPreset ||
        draftUseCustomAccent != theme.useCustomAccent ||
        draftCustomAccentHex != theme.customAccentHex ||
        draftAppearance != theme.appearance
    }
    
    var draftAccentColor: Color {
        if draftUseCustomAccent, let c = Color(hex: draftCustomAccentHex) {
            return c
        }
        return draftAccentPreset.color
    }
    
    func saveToTheme() {
        // 依序套用並存入 UserDefaults（ThemeStore 裡面已做 set...）
        theme.setFontScale(draftFontScale)
        theme.setBackgroundStyle(draftBackgroundStyle)
        
        if draftUseCustomAccent {
            theme.setCustomAccentHex(draftCustomAccentHex)
            theme.setUseCustomAccent(true)
        } else {
            theme.setAccentPreset(draftAccentPreset)
            theme.setUseCustomAccent(false)
        }
        
        theme.setAppearance(draftAppearance)
        
        // 若善甯有某些地方不會自動刷新，可保險 bump 一次
        theme.bumpRefresh()
    }
}

private struct ThemePreviewCard: View {
    
    let backgroundStyle: ThemeStore.BackgroundStyle
    let accentColor: Color
    let fontScale: Double
    let appearance: ThemeStore.AppAppearance
    
    var body: some View {
        ZStack {
            previewBackground
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 10, height: 10)
                    Text("主色預覽")
                        .font(.headline)
                        .scaleEffect(fontScale)
                    Spacer()
                    Text(appearance.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 10) {
                    Button {} label: {
                        Label("操作", systemImage: "plus")
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(accentColor.opacity(0.20))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.thinMaterial)
                        .frame(height: 34)
                        .overlay(
                            HStack {
                                Text("卡片")
                                    .font(.subheadline)
                                    .scaleEffect(fontScale)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                                .padding(.horizontal, 12)
                        )
                }
                
                Text("字級倍率會影響這段文字的大小。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .scaleEffect(fontScale)
            }
            .padding(14)
        }
        .frame(height: 130)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(accentColor.opacity(0.35), lineWidth: 1)
        )
        .preferredColorScheme(appearance.preferredColorScheme)
    }
    
    @ViewBuilder
    var previewBackground: some View {
        switch backgroundStyle {
        case .system:
            Color.clear
                .background(.thinMaterial)
            
        case .gradient:
            LinearGradient(
                colors: [accentColor.opacity(0.35), Color.black.opacity(0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .background(.thinMaterial)
            
        case .light:
            Color.white.opacity(0.08)
                .background(.thinMaterial)
        }
    }
}
