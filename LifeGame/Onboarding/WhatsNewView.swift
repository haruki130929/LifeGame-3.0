import SwiftUI

// MARK: - 版本更新內容

struct WhatsNewView: View {
    let version: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 標題
            VStack(spacing: 8) {
                Text("v\(version) 更新內容")
                    .font(.title.bold())

                Text("以下是這次更新的重點")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 36)

            // 更新項目
            VStack(alignment: .leading, spacing: 24) {
                ForEach(items, id: \.title) { item in
                    featureRow(item)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // 繼續按鈕
            Button(action: onDismiss) {
                Text("繼續")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
        .padding(.vertical, 24)
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

    static func items(for version: String) -> [WhatsNewItem] {
        switch version {
        case "1.05":
            return [
                WhatsNewItem(
                    icon: "book.fill",
                    title: "使用教學",
                    description: "在設定中新增「使用教學」頁面，隨時查看 App 概念和各功能操作說明。",
                    color: .blue
                ),
                WhatsNewItem(
                    icon: "person.crop.circle.fill",
                    title: "Apple ID 登入",
                    description: "支援 Sign in with Apple，登入後自動開啟 iCloud 同步，刪除 App 重裝也不怕遺失資料。",
                    color: .green
                ),
                WhatsNewItem(
                    icon: "applewatch",
                    title: "Watch 雙向同步",
                    description: "在 Apple Watch 上記錄心情或勾選待辦，回到 iPhone/iPad 時資料自動合併。",
                    color: .cyan
                ),
                WhatsNewItem(
                    icon: "exclamationmark.triangle.fill",
                    title: "錯誤通知改善",
                    description: "儲存或同步失敗時，畫面頂部會顯示通知提醒，不再靜默失敗。",
                    color: .orange
                ),
            ]
        case "1.03":
            return [
                WhatsNewItem(
                    icon: "circle.dotted",
                    title: "圓環選單改進",
                    description: "修復了功能頁「＋」按鈕無法選取的問題，圓環選單在所有頁面都能正常使用。",
                    color: .blue
                ),
                WhatsNewItem(
                    icon: "arrow.down.circle.fill",
                    title: "版本更新提醒",
                    description: "有新版本時，設定圖示會出現紅點提醒，點擊即可前往 App Store 更新。",
                    color: .red
                ),
                WhatsNewItem(
                    icon: "face.smiling.fill",
                    title: "心情紀錄回饋",
                    description: "紀錄每小時心情後，會顯示「已紀錄」的確認訊息。",
                    color: .green
                ),
                WhatsNewItem(
                    icon: "icloud.fill",
                    title: "資料同步強化",
                    description: "角色設定資料已支援 iCloud 同步，所有裝置間保持一致。",
                    color: .cyan
                ),
            ]
        case "1.01":
            return [
                WhatsNewItem(
                    icon: "hand.tap.fill",
                    title: "全新手勢圓環選單",
                    description: "長按右下角「＋」按鈕，滑動手指選擇功能。在圓環邊緣拖動還可以滾動瀏覽更多選項。",
                    color: .blue
                ),
                WhatsNewItem(
                    icon: "icloud.fill",
                    title: "iCloud 同步改進",
                    description: "修復了 iCloud 設定在重啟後被關閉的問題。建議到設定中開啟 iCloud 同步，讓資料在所有裝置間保持一致。",
                    color: .cyan
                ),
                WhatsNewItem(
                    icon: "clock.fill",
                    title: "時間圓環排版優化",
                    description: "手機版時間圓環改為上下排列，圓環更大更清楚。",
                    color: .orange
                ),
            ]
        default:
            return []
        }
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
