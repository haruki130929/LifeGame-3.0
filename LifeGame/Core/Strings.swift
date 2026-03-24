import Foundation

// MARK: - 集中管理的 UI 字串
// 未來多語系時，只需在這裡替換成 String(localized:) 即可

enum L10n {

    // MARK: - 通用動作
    enum Action {
        static let done = "完成"
        static let cancel = "取消"
        static let save = "儲存"
        static let delete = "刪除"
        static let edit = "編輯"
        static let add = "加入"
        static let confirm = "確定"
        static let retry = "重試"
        static let close = "關閉"
        static let back = "返回"
        static let next = "下一步"
        static let skip = "略過"
    }

    // MARK: - 導航 / 頁面標題
    enum Title {
        static let settings = "設定"
        static let calendar = "行事曆"
        static let diary = "日記"
        static let wish = "願望"
        static let ledger = "記帳"
        static let dailyLog = "每日紀錄"
        static let todoQuadrant = "待辦四象限"
        static let tomorrowRing = "時間圓環"
        static let bagRequired = "整理書包"
        static let monthlyScore = "本月結算"
        static let moodThermometer = "心情溫度計"
        static let mandala = "曼陀羅圖表"
        static let storageSettings = "儲存設定"
        static let backupSettings = "資料備份"
        static let themeSettings = "主題與配色"
    }

    // MARK: - 設定頁
    enum Settings {
        static let featureSettings = "功能設定"
        static let appearance = "外觀設定"
        static let dataStorage = "資料儲存"
        static let storageMethod = "儲存方式"
        static let feedback = "意見回饋"
        static let shareFeedback = "分享使用體驗"
        static let versionUpdate = "版本更新"
        static let latestVersion = "已是最新版本"
        static let about = "關於"
        static let version = "版本"
        static let developer = "開發者"
    }

    // MARK: - iCloud / 帳號
    enum Account {
        static let accountStatus = "帳號狀態"
        static let signedInICloud = "已登入 iCloud"
        static let notSignedIn = "未登入 iCloud"
        static let iCloudSync = "iCloud 同步"
        static let iCloudSyncDesc = "資料會自動同步到 iCloud，可在多台裝置間共享"
        static let localOnly = "僅限本機"
        static let localOnlyDesc = "資料僅儲存在此裝置"
        static let signInWithApple = "使用 Apple 登入"
    }

    // MARK: - Onboarding
    enum Onboarding {
        static let welcome = "歡迎來到 LifeGame"
        static let getStarted = "開始使用"
        static let chooseRole = "選擇你的身份"
        static let student = "學生"
        static let worker = "上班族"
    }

    // MARK: - 待辦
    enum Todo {
        static let addTodo = "新增待辦事項"
        static let noTodos = "尚無待辦"
        static let inputPlaceholder = "輸入待辦事項"
    }

    // MARK: - 心情
    enum Mood {
        static let recordMood = "記錄心情"
        static let todayMood = "今日心情"
    }

    // MARK: - 錯誤訊息
    enum Error {
        static let saveFailed = "資料儲存失敗"
        static let loadFailed = "資料讀取失敗"
        static let deleteFailed = "資料刪除失敗"
        static let syncFailed = "同步失敗"
        static let storageNotReady = "儲存系統尚未就緒"
        static let unknownError = "未知錯誤"
    }

    // MARK: - 空狀態
    enum Empty {
        static let noData = "尚無資料"
        static let noWish = "尚無願望清單"
        static let noRecord = "尚無紀錄"
    }
}
