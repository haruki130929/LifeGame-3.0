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
    private static let lastVersionKey = "whats_new_last_shown_version"

    /// 目前 app 版本
    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    /// 上次顯示過更新內容的版本
    static var lastShownVersion: String? {
        UserDefaults.standard.string(forKey: lastVersionKey)
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
        UserDefaults.standard.set(currentVersion, forKey: lastVersionKey)
    }

    /// 測試用：清除紀錄，讓 shouldShowWhatsNew 重新觸發
    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: lastVersionKey)
    }
}
