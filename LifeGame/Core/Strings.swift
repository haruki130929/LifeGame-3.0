import Foundation

// MARK: - 集中管理的 UI 字串
//
// 一律用 computed var 而不是 static let：Swift 的 static let 在 process 內只會求值一次，
// 使用者在 App 內切換語言後就會凍在舊語言。computed var 每次讀取都重新解析，
// 成本可忽略，卻是即時切換能正確運作的前提。

enum L10n {

    // MARK: - 通用動作
    enum Action {
        static var done: String { String(localized: "完成") }
        static var cancel: String { String(localized: "取消") }
        static var save: String { String(localized: "儲存") }
        static var delete: String { String(localized: "刪除") }
        static var edit: String { String(localized: "編輯") }
        static var add: String { String(localized: "加入") }
        static var confirm: String { String(localized: "確定") }
        static var retry: String { String(localized: "重試") }
        static var close: String { String(localized: "關閉") }
        static var back: String { String(localized: "返回") }
        static var next: String { String(localized: "下一步") }
        static var skip: String { String(localized: "略過") }
    }

    // MARK: - 導航 / 頁面標題
    enum Title {
        static var settings: String { String(localized: "設定") }
        static var calendar: String { String(localized: "行事曆") }
        static var diary: String { String(localized: "日記") }
        static var wish: String { String(localized: "願望") }
        static var ledger: String { String(localized: "記帳") }
        static var dailyLog: String { String(localized: "每日紀錄") }
        static var todoQuadrant: String { String(localized: "待辦四象限") }
        static var tomorrowRing: String { String(localized: "時間圓環") }
        static var bagRequired: String { String(localized: "整理書包") }
        static var monthlyScore: String { String(localized: "本月結算") }
        static var moodThermometer: String { String(localized: "心情溫度計") }
        static var mandala: String { String(localized: "曼陀羅圖表") }
        static var storageSettings: String { String(localized: "儲存設定") }
        static var backupSettings: String { String(localized: "資料備份") }
        static var themeSettings: String { String(localized: "主題與配色") }
    }

    // MARK: - 設定頁
    enum Settings {
        static var featureSettings: String { String(localized: "功能設定") }
        static var appearance: String { String(localized: "外觀設定") }
        static var dataStorage: String { String(localized: "資料儲存") }
        static var storageMethod: String { String(localized: "儲存方式") }
        static var feedback: String { String(localized: "意見回饋") }
        static var shareFeedback: String { String(localized: "分享使用體驗") }
        static var versionUpdate: String { String(localized: "版本更新") }
        static var latestVersion: String { String(localized: "已是最新版本") }
        static var about: String { String(localized: "關於") }
        static var version: String { String(localized: "版本") }
        static var developer: String { String(localized: "開發者") }
        static var developerNote: String { String(localized: "開發者的話") }
        static var changelog: String { String(localized: "開發日誌") }
        static var tellMeWhatYouThink: String { String(localized: "告訴我你的想法") }
    }

    // MARK: - iCloud / 帳號
    enum Account {
        static var accountStatus: String { String(localized: "帳號狀態") }
        static var signedInICloud: String { String(localized: "已登入 iCloud") }
        static var notSignedIn: String { String(localized: "未登入 iCloud") }
        static var iCloudSync: String { String(localized: "iCloud 同步") }
        static var iCloudSyncDesc: String { String(localized: "資料會自動同步到 iCloud，可在多台裝置間共享") }
        static var localOnly: String { String(localized: "僅限本機") }
        static var localOnlyDesc: String { String(localized: "資料僅儲存在此裝置") }
        static var signInWithApple: String { String(localized: "使用 Apple 登入") }
    }

    // MARK: - Onboarding
    enum Onboarding {
        static var welcome: String { String(localized: "歡迎來到 LifeGame") }
        static var getStarted: String { String(localized: "開始使用") }
        static var chooseRole: String { String(localized: "選擇你的身份") }
        static var student: String { String(localized: "學生") }
        static var worker: String { String(localized: "上班族") }
    }

    // MARK: - 待辦
    enum Todo {
        static var addTodo: String { String(localized: "新增待辦事項") }
        static var noTodos: String { String(localized: "尚無待辦") }
        static var inputPlaceholder: String { String(localized: "輸入待辦事項") }
    }

    // MARK: - 心情
    enum Mood {
        static var recordMood: String { String(localized: "記錄心情") }
        static var todayMood: String { String(localized: "今日心情") }
    }

    // MARK: - 錯誤訊息
    enum Error {
        static var saveFailed: String { String(localized: "資料儲存失敗") }
        static var loadFailed: String { String(localized: "資料讀取失敗") }
        static var deleteFailed: String { String(localized: "資料刪除失敗") }
        static var syncFailed: String { String(localized: "同步失敗") }
        static var storageNotReady: String { String(localized: "儲存系統尚未就緒") }
        static var unknownError: String { String(localized: "未知錯誤") }
    }

    // MARK: - 空狀態
    enum Empty {
        static var noData: String { String(localized: "尚無資料") }
        static var noWish: String { String(localized: "尚無願望清單") }
        static var noRecord: String { String(localized: "尚無紀錄") }
    }

    // MARK: - 使用教學
    enum Tutorial {
        static var title: String { String(localized: "使用教學") }
        static var concepts: String { String(localized: "基本概念") }
        static var features: String { String(localized: "功能介紹") }
        static var operationTips: String { String(localized: "操作技巧") }
        static var replayCoachMark: String { String(localized: "重新播放新手引導") }
        static var tip: String { String(localized: "小技巧") }
    }
}
