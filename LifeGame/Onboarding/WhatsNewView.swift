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

    static func items(for version: String) -> [WhatsNewItem] {
        switch version {
        case "1.20":
            return [
                WhatsNewItem(
                    icon: "bubble.left.and.bubble.right",
                    title: String(localized: "選緘溝通板"),
                    description: String(localized: "面對面溝通工具：畫面上下分半，上方翻轉 180° 讓對方閱讀，你在下方即時打字。支援對話歷史、匯出紀錄、字體大小調整。"),
                    color: .cyan
                ),
                WhatsNewItem(
                    icon: "chart.xyaxis.line",
                    title: String(localized: "每日紀錄圖表"),
                    description: String(localized: "情緒趨勢、睡眠時數、身體不適、待辦完成度、起床就寢時間，5 張圖表一目了然。可選 1 週到 3 個月的時間區間。"),
                    color: .orange
                ),
                WhatsNewItem(
                    icon: "calendar.badge.plus",
                    title: String(localized: "行事曆重複行程"),
                    description: String(localized: "新增行程時可設定重複頻率：每天、每週、每兩週、每月，自訂重複次數。"),
                    color: .green
                ),
                WhatsNewItem(
                    icon: "clock.badge.checkmark",
                    title: String(localized: "時間圓環即時顯示課表"),
                    description: String(localized: "修復開啟 App 時卡片不顯示課表的問題，現在一開啟就能看到今天的課表。"),
                    color: .purple
                ),
                WhatsNewItem(
                    icon: "ladybug.fill",
                    title: String(localized: "穩定性大幅提升"),
                    description: String(localized: "修復右下角按鈕導致畫面閃爍、天氣與圖表數據顯示錯誤、跨裝置同步等多項問題。"),
                    color: .red
                ),
            ]
        case "1.19":
            return [
                WhatsNewItem(
                    icon: "chart.bar.xaxis",
                    title: String(localized: "全新甘特圖"),
                    description: String(localized: "新增甘特圖功能，可建立任務與子任務、設定里程碑與緩衝時間。支援日/週/月切換，拖拉調整時長，序列子任務自動排程。"),
                    color: .blue
                ),
                WhatsNewItem(
                    icon: "arrow.uturn.backward.circle",
                    title: String(localized: "簡略模式強化"),
                    description: String(localized: "快速模式新增「返回上一張」按鈕，刷錯了可以回來。右下角新增卡片編輯按鈕，直接管理要顯示的功能。"),
                    color: .green
                ),
                WhatsNewItem(
                    icon: "calendar.badge.plus",
                    title: String(localized: "每週固定行程"),
                    description: String(localized: "行事曆新增行程時可選「每週固定行程」，自動建立 12 週重複行程，也會同步到 Apple 行事曆。"),
                    color: .orange
                ),
                WhatsNewItem(
                    icon: "arrow.triangle.2.circlepath",
                    title: String(localized: "同步 Apple 行事曆"),
                    description: String(localized: "行事曆設定頁新增同步按鈕，一鍵匯入 Apple 行事曆未來 3 個月的行程。"),
                    color: .cyan
                ),
                WhatsNewItem(
                    icon: "doc.text.magnifyingglass",
                    title: String(localized: "檢視每日紀錄"),
                    description: String(localized: "每日紀錄右下角「＋」新增「檢視紀錄」選項，可選擇日期範圍瀏覽過去的紀錄。"),
                    color: .purple
                ),
                WhatsNewItem(
                    icon: "ladybug.fill",
                    title: String(localized: "穩定性提升"),
                    description: String(localized: "修復多項 CloudKit 同步問題、資料重複、版本相容性問題，整體更穩定。"),
                    color: .red
                ),
            ]
        case "1.07":
            return [
                WhatsNewItem(
                    icon: "clock.badge.checkmark",
                    title: String(localized: "時間圓環大改版"),
                    description: String(localized: "全新雙圈設計：內圈「預定行程」、外圈「實際執行」，一眼看出計畫與現實的差距。"),
                    color: .orange
                ),
                WhatsNewItem(
                    icon: "plus.circle.dashed",
                    title: String(localized: "空時段一鍵新增"),
                    description: String(localized: "空時段用虛線框顯示，中央有「＋」按鈕，輕點就能在該空檔新增行程，不用再自己選時間。"),
                    color: .green
                ),
                WhatsNewItem(
                    icon: "hand.tap.fill",
                    title: String(localized: "長按拖曳更直覺"),
                    description: String(localized: "長按時段會浮起並震動回饋，拖曳即可移動；放開後自動回到軌道上。時段之間會自動避免重疊。"),
                    color: .purple
                ),
                WhatsNewItem(
                    icon: "book.closed.fill",
                    title: String(localized: "課表系統整合"),
                    description: String(localized: "新增獨立課表模組，設定每週固定課程後，系統會每天自動填入內圈並依時段扣除 HP/FP。"),
                    color: .blue
                ),
                WhatsNewItem(
                    icon: "paintpalette.fill",
                    title: String(localized: "主題色全 App 統一"),
                    description: String(localized: "你在設定選的主題色現在會套用到所有標示 — 今日日期、選取指示、按鈕等等，視覺終於一致。"),
                    color: .pink
                ),
                WhatsNewItem(
                    icon: "circle.grid.cross",
                    title: String(localized: "顏色選擇器升級"),
                    description: String(localized: "顏色選擇器改為左右滑動分頁，圓形色塊更易辨識，七種日本傳統色分類隨手切換。"),
                    color: .red
                ),
            ]
        case "1.06":
            return [
                WhatsNewItem(
                    icon: "icloud.fill",
                    title: String(localized: "iCloud 同步修復"),
                    description: String(localized: "修復 CloudKit 同步失敗的問題，資料現在能正確備份至 iCloud，重裝 App 也不會遺失。"),
                    color: .cyan
                ),
                WhatsNewItem(
                    icon: "pencil.and.list.clipboard",
                    title: String(localized: "全新「練習日記」"),
                    description: String(localized: "取代原有弓道筆記，可自訂練習項目與欄位，支援數值、評分、文字等多種記錄方式。"),
                    color: .blue
                ),
                WhatsNewItem(
                    icon: "chart.pie.fill",
                    title: String(localized: "練習日記圖表分析"),
                    description: String(localized: "練習日記支援圓餅圖、折線圖、雷達圖，輕鬆追蹤練習成效與趨勢。"),
                    color: .purple
                ),
                WhatsNewItem(
                    icon: "trash.fill",
                    title: String(localized: "切頁可刪除"),
                    description: String(localized: "編輯切頁時底部新增刪除按鈕，不需要的切頁可以輕鬆移除。"),
                    color: .red
                ),
                WhatsNewItem(
                    icon: "clock.fill",
                    title: String(localized: "時間圓環教學修正"),
                    description: String(localized: "教學彈窗改為進入功能頁時才顯示，不再於主頁重複彈出。"),
                    color: .orange
                ),
            ]
        case "1.05":
            return [
                WhatsNewItem(
                    icon: "book.fill",
                    title: String(localized: "使用教學"),
                    description: String(localized: "左側選單新增「使用教學」入口，第一次進入各功能頁時也會自動彈出教學說明。"),
                    color: .blue
                ),
                WhatsNewItem(
                    icon: "person.crop.circle.fill",
                    title: String(localized: "Apple ID 登入 & iCloud 同步"),
                    description: String(localized: "支援 Sign in with Apple，資料自動同步到 iCloud，刪除 App 重裝也不怕遺失資料。"),
                    color: .green
                ),
                WhatsNewItem(
                    icon: "lightbulb.fill",
                    title: String(localized: "新手引導升級"),
                    description: String(localized: "聚光燈引導流程新增「使用教學」位置提示，讓你更快上手。"),
                    color: .yellow
                ),
                WhatsNewItem(
                    icon: "exclamationmark.triangle.fill",
                    title: String(localized: "穩定性改善"),
                    description: String(localized: "修復多項閃退問題，儲存失敗時會顯示通知提醒。"),
                    color: .orange
                ),
            ]
        case "1.03":
            return [
                WhatsNewItem(
                    icon: "circle.dotted",
                    title: String(localized: "圓環選單改進"),
                    description: String(localized: "修復了功能頁「＋」按鈕無法選取的問題，圓環選單在所有頁面都能正常使用。"),
                    color: .blue
                ),
                WhatsNewItem(
                    icon: "arrow.down.circle.fill",
                    title: String(localized: "版本更新提醒"),
                    description: String(localized: "有新版本時，設定圖示會出現紅點提醒，點擊即可前往 App Store 更新。"),
                    color: .red
                ),
                WhatsNewItem(
                    icon: "face.smiling.fill",
                    title: String(localized: "心情紀錄回饋"),
                    description: String(localized: "紀錄每小時心情後，會顯示「已紀錄」的確認訊息。"),
                    color: .green
                ),
                WhatsNewItem(
                    icon: "icloud.fill",
                    title: String(localized: "資料同步強化"),
                    description: String(localized: "角色設定資料已支援 iCloud 同步，所有裝置間保持一致。"),
                    color: .cyan
                ),
            ]
        case "1.01":
            return [
                WhatsNewItem(
                    icon: "hand.tap.fill",
                    title: String(localized: "全新手勢圓環選單"),
                    description: String(localized: "長按右下角「＋」按鈕，滑動手指選擇功能。在圓環邊緣拖動還可以滾動瀏覽更多選項。"),
                    color: .blue
                ),
                WhatsNewItem(
                    icon: "icloud.fill",
                    title: String(localized: "iCloud 同步改進"),
                    description: String(localized: "修復了 iCloud 設定在重啟後被關閉的問題。建議到設定中開啟 iCloud 同步，讓資料在所有裝置間保持一致。"),
                    color: .cyan
                ),
                WhatsNewItem(
                    icon: "clock.fill",
                    title: String(localized: "時間圓環排版優化"),
                    description: String(localized: "手機版時間圓環改為上下排列，圓環更大更清楚。"),
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
