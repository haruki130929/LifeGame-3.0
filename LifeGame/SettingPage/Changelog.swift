import SwiftUI

// MARK: - 版本紀錄（單一資料來源）
//
// 這份資料同時餵給兩個地方：
//   1. `WhatsNewView` — 更新後第一次啟動時彈出的「這版改了什麼」
//   2. `ChangelogView` — 設定頁「開發日誌」裡的完整歷史
//
// 兩邊共用同一份，才不會出現「彈窗說有這個功能、日誌裡卻查不到」的落差。

/// 一次版本發布。
struct ChangelogRelease: Identifiable {

    /// 顯示與比對用的版本號，對應 `CFBundleShortVersionString`。
    let version: String

    /// 發布日期字串（`2026.08.13`）。刻意用字串而不是 `Date`：
    /// 這是寫死的歷史紀錄，不需要時區換算，也不該被使用者的日曆設定影響。
    let date: String

    /// 一句話定調這個版本在做什麼，列表收合時只會看到它。
    let summary: String

    /// 這版的更新項目，與 WhatsNew 彈窗共用。
    let items: [WhatsNewItem]

    /// 同一份內容曾經用過的其他版本號。
    ///
    /// v1.07 準備上架時，Xcode Archive 的自動遞增把版本號跳成了 1.17，
    /// 實際送出去的 build 是 1.17 —— 但舊的 WhatsNew 是用 "1.07" 當 key。
    /// 列表顯示 `version`（使用者裝置上真正看到的號碼），比對時兩個都認。
    let aliases: [String]

    var id: String { version }

    init(version: String, date: String, summary: String, aliases: [String] = [], items: [WhatsNewItem]) {
        self.version = version
        self.date = date
        self.summary = summary
        self.aliases = aliases
        self.items = items
    }

    func matches(_ version: String) -> Bool {
        self.version == version || aliases.contains(version)
    }
}

enum Changelog {

    /// 全部版本，新到舊。
    ///
    /// 一律用 computed var 而不是 static let —— 底下的 `String(localized:)` 在
    /// static let 裡只會求值一次，使用者在 App 內切換語言後就會凍在舊語言。
    /// 理由與 `L10n` 相同，見 `Core/Strings.swift`。
    static var releases: [ChangelogRelease] {
        [
            ChangelogRelease(
                version: "1.20",
                date: "2026.08.13",
                summary: "跨出 iPhone：Mac 版、桌面小工具、三語介面",
                items: [
                    WhatsNewItem(
                        icon: "bubble.left.and.bubble.right",
                        title: String(localized: "選緘溝通板"),
                        description: String(localized: "面對面溝通工具：畫面上下分半，上方翻轉 180° 讓對方閱讀，你在下方即時打字。支援對話歷史、匯出紀錄、字體大小調整。"),
                        color: .cyan
                    ),
                    WhatsNewItem(
                        icon: "desktopcomputer",
                        title: String(localized: "Mac 版登場"),
                        description: String(localized: "LifeGame 現在可以在 Mac 上使用。支援視窗縮放、選單列鍵盤快捷鍵、滑鼠移過卡片的高亮回饋。"),
                        color: .indigo
                    ),
                    WhatsNewItem(
                        icon: "square.grid.2x2",
                        title: String(localized: "桌面小工具"),
                        description: String(localized: "把今日狀態與待辦事項放到主畫面。待辦小工具可直接勾選完成，不必打開 App；還能自選要顯示哪個象限與淺色深色。"),
                        color: .teal
                    ),
                    WhatsNewItem(
                        icon: "bolt.badge.clock",
                        title: String(localized: "即時動態與通知"),
                        description: String(localized: "今日狀態與待辦可顯示在鎖定畫面和動態島，隨時看到進度。通知也能直接操作，不用進 App。"),
                        color: .pink
                    ),
                    WhatsNewItem(
                        icon: "globe",
                        title: String(localized: "支援繁體中文、英文、日文"),
                        description: String(localized: "全 App 介面完成三語在地化，可在設定中切換語言。"),
                        color: .blue
                    ),
                    WhatsNewItem(
                        icon: "chart.xyaxis.line",
                        title: String(localized: "每日紀錄圖表"),
                        description: String(localized: "情緒趨勢、睡眠時數、身體不適、待辦完成度、起床就寢時間，5 張圖表一目了然。時間區間可選 1 週到全部。也支援匯出紀錄與調整文字大小。"),
                        color: .orange
                    ),
                    WhatsNewItem(
                        icon: "lightbulb",
                        title: String(localized: "動力筆記"),
                        description: String(localized: "把「遇到什麼情況」和「當時什麼方法有效」記下來，下次卡住時可以直接翻出來用。"),
                        color: .yellow
                    ),
                    WhatsNewItem(
                        icon: "calendar.badge.plus",
                        title: String(localized: "行事曆大幅強化"),
                        description: String(localized: "新增重複行程（每天、每週、每兩週、每月）、Apple 風格月檢視、同步 Apple 行事曆的顏色與範圍設定，文字大小也可調整。"),
                        color: .green
                    ),
                    WhatsNewItem(
                        icon: "checklist",
                        title: String(localized: "待辦更好用"),
                        description: String(localized: "到期日與時間分開設定，完成的待辦會在一週後自動收起，時段時間也可以自訂。"),
                        color: .purple
                    ),
                    WhatsNewItem(
                        icon: "wrench.and.screwdriver.fill",
                        title: String(localized: "穩定性大幅提升"),
                        description: String(localized: "修復右下角按鈕導致畫面閃爍、天氣與圖表數據顯示錯誤、跨裝置同步、課表未即時顯示等多項問題。"),
                        color: .red
                    ),
                ]
            ),

            ChangelogRelease(
                version: "1.19",
                date: "2026.04.12",
                summary: "甘特圖登場，長期計畫也能追",
                items: [
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
            ),

            // 1.18 以前沒有做過 WhatsNew 彈窗，以下內容是為了補齊開發日誌而回頭整理的。
            ChangelogRelease(
                version: "1.18",
                date: "2026.04.08",
                summary: "跨裝置同步與待辦到期日",
                items: [
                    WhatsNewItem(
                        icon: "arrow.triangle.2.circlepath",
                        title: "跨裝置同步",
                        description: "iPhone、iPad 之間的資料同步改寫，換裝置打開時不用再等、也不會蓋掉另一台剛寫的紀錄。",
                        color: .cyan
                    ),
                    WhatsNewItem(
                        icon: "calendar.badge.clock",
                        title: "待辦可設到期日",
                        description: "四象限的待辦可以指定到期日，快到期的會排在前面。",
                        color: .purple
                    ),
                    WhatsNewItem(
                        icon: "clock.arrow.circlepath",
                        title: "每日紀錄可補寫過去的日期",
                        description: "忘記寫的那天，現在可以選日期回頭補上。",
                        color: .orange
                    ),
                    WhatsNewItem(
                        icon: "book.closed.fill",
                        title: "課表修正",
                        description: "修復課表編輯畫面第一次點沒有反應的問題。",
                        color: .red
                    ),
                ]
            ),

            ChangelogRelease(
                version: "1.17",
                date: "2026.04.06",
                summary: "時間圓環大改版",
                aliases: ["1.07"],
                items: [
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
            ),

            ChangelogRelease(
                version: "1.06",
                date: "2026.03.26",
                summary: "iCloud 同步修復與練習日記",
                items: [
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
            ),

            ChangelogRelease(
                version: "1.05",
                date: "2026.03.25",
                summary: "Apple ID 登入與使用教學",
                items: [
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
            ),

            ChangelogRelease(
                version: "1.03",
                date: "2026.03.23",
                summary: "圓環選單修復與版本更新提醒",
                items: [
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
            ),

            ChangelogRelease(
                version: "1.01",
                date: "2026.03.21",
                summary: "手勢圓環選單",
                items: [
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
            ),

            ChangelogRelease(
                version: "1.0",
                date: "2026.03.20",
                summary: "LifeGamer 上架",
                items: [
                    WhatsNewItem(
                        icon: "heart.text.square",
                        title: "把一天變成看得見的東西",
                        description: "一天切成幾個時段，用 HP、FP、MP 三個數值追蹤體力、專注力與心情，配上每小時的心情溫度計。",
                        color: .pink
                    ),
                    WhatsNewItem(
                        icon: "square.grid.2x2",
                        title: "會跟著時段換的儀表板",
                        description: "早上、下午、睡前想看的東西本來就不一樣。卡片會跟著目前時段自動換一組，也可以自己編輯切頁。",
                        color: .blue
                    ),
                    WhatsNewItem(
                        icon: "clock",
                        title: "時間圓環",
                        description: "把一天的行程畫成一個圓，什麼時候滿、什麼時候空，一眼就看得出來。",
                        color: .orange
                    ),
                    WhatsNewItem(
                        icon: "list.bullet.clipboard",
                        title: "待辦四象限、行事曆、每日紀錄",
                        description: "重要與緊急分四格排待辦，行事曆看行程，每天用問題模組留下一段紀錄。",
                        color: .purple
                    ),
                    WhatsNewItem(
                        icon: "backpack",
                        title: "整理書包與曼陀羅圖表",
                        description: "出門前照清單確認一次，長期目標則用曼陀羅九宮格慢慢展開。",
                        color: .green
                    ),
                    WhatsNewItem(
                        icon: "iphone",
                        title: "一般模式與簡略模式",
                        description: "iPhone 可以在完整版面與左右滑動的簡略版面之間切換；iPad 則是自適應的大版面。",
                        color: .indigo
                    ),
                ]
            ),
        ]
    }

    /// 找出某個版本號對應的發布紀錄（含歷史別名）。
    static func release(for version: String) -> ChangelogRelease? {
        releases.first { $0.matches(version) }
    }

    /// 某個版本的更新項目；沒有紀錄就回空陣列。
    static func items(for version: String) -> [WhatsNewItem] {
        release(for: version)?.items ?? []
    }
}
