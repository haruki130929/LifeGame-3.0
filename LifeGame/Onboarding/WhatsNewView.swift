import SwiftUI

// MARK: - 版本更新內容

struct WhatsNewView: View {
    let version: String
    let onDismiss: () -> Void
    @EnvironmentObject private var theme: ThemeStore

    var body: some View {
        VStack(spacing: 0) {
            // 標題
            VStack(spacing: 8) {
                Text("v\(version) 更新內容")
                    .font(.title.bold())

                Text("以下是這次更新的重點")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 32)
            .padding(.bottom, 24)

            // 更新項目（ScrollView 確保內容多時可捲動）
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(items, id: \.title) { item in
                        featureRow(item)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 8)
            }

            // 繼續按鈕
            Button(action: onDismiss) {
                Text("繼續")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accentColor)
            .padding(.horizontal, 32)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }

    private func featureRow(_ item: WhatsNewItem) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: item.icon)
                .font(.system(size: 28))
                .foregroundStyle(item.color)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - 各版本更新內容

    private var items: [WhatsNewItem] {
        WhatsNewView.items(for: version)
    }

    /// 版本內容的唯一來源是 `Changelog`，設定頁的「開發日誌」讀的是同一份。
    static func items(for version: String) -> [WhatsNewItem] {
        Changelog.items(for: version)
    }

    /// 檢查某版本是否有更新內容需要顯示
    static func hasContent(for version: String) -> Bool {
        !items(for: version).isEmpty
    }
}

struct WhatsNewItem {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - 版本追蹤

enum VersionTracker {
    private static let storageKey = "onboarding.whatsNewLastVersion"
    private static let legacyKey = "whats_new_last_shown_version"

    /// 目前 app 版本
    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    /// 上次顯示過更新內容的版本
    static var lastShownVersion: String? {
        migrateLegacyIfNeeded()
        return StorageManager.load(String.self, forKey: storageKey)
    }

    /// 是否需要顯示更新內容
    static var shouldShowWhatsNew: Bool {
        let current = currentVersion
        let last = lastShownVersion

        // 已經看過這個版本 → 不顯示
        if last == current { return false }

        // 有更新內容就顯示（包含舊用戶第一次遇到此機制）
        return WhatsNewView.hasContent(for: current)
    }

    /// 標記目前版本已顯示
    static func markAsShown() {
        StorageManager.save(currentVersion, forKey: storageKey)
    }

    /// 測試用：清除紀錄，讓 shouldShowWhatsNew 重新觸發
    static func resetForTesting() {
        StorageManager.remove(forKey: storageKey)
    }

    private static func migrateLegacyIfNeeded() {
        let ud = UserDefaults.standard
        guard let old = ud.string(forKey: legacyKey) else { return }
        StorageManager.save(old, forKey: storageKey)
        ud.removeObject(forKey: legacyKey)
    }
}
