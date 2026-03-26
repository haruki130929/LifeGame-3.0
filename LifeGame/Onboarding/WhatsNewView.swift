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
        case "1.06":
            return [
                WhatsNewItem(
                    icon: "icloud.fill",
                    title: "iCloud 同步修復",
                    description: "修復 CloudKit 同步失敗的問題，資料現在能正確備份至 iCloud，重裝 App 也不會遺失。",
                    color: .cyan
                ),
                WhatsNewItem(
                    icon: "pencil.and.list.clipboard",
                    title: "全新「練習日記」",
                    description: "取代原有弓道筆記，可自訂練習項目與欄位，支援數值、評分、文字等多種記錄方式。",
                    color: .blue
                ),
                WhatsNewItem(
                    icon: "chart.pie.fill",
                    title: "練習日記圖表分析",
                    description: "練習日記支援圓餅圖、折線圖、雷達圖，輕鬆追蹤練習成效與趨勢。",
                    color: .purple
                ),
                WhatsNewItem(
                    icon: "trash.fill",
                    title: "切頁可刪除",
                    description: "編輯切頁時底部新增刪除按鈕，不需要的切頁可以輕鬆移除。",
                    color: .red
                ),
                WhatsNewItem(
                    icon: "clock.fill",
                    title: "時間圓環教學修正",
                    description: "教學彈窗改為進入功能頁時才顯示，不再於主頁重複彈出。",
                    color: .orange
                ),
            ]
        case "1.05":
            return [
                WhatsNewItem(
                    icon: "book.fill",
                    title: "使用教學",
                    description: "左側選單新增「使用教學」入口，第一次進入各功能頁時也會自動彈出教學說明。",
                    color: .blue
                ),
                WhatsNewItem(
                    icon: "person.crop.circle.fill",
                    title: "Apple ID 登入 & iCloud 同步",
                    description: "支援 Sign in with Apple，資料自動同步到 iCloud，刪除 App 重裝也不怕遺失資料。",
                    color: .green
                ),
                WhatsNewItem(
                    icon: "lightbulb.fill",
                    title: "新手引導升級",
                    description: "聚光燈引導流程新增「使用教學」位置提示，讓你更快上手。",
                    color: .yellow
                ),
                WhatsNewItem(
                    icon: "exclamationmark.triangle.fill",
                    title: "穩定性改善",
                    description: "修復多項閃退問題，儲存失敗時會顯示通知提醒。",
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
