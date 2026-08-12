// File: Core/AppLocalization.swift
//
// App 內即時切換語言的核心。
//
// 這個 App 的字串分成兩條互不相通的解析路徑，兩條都要處理才不會變成「半中半日」：
//
//   1. String(localized: "中文")（約 1,568 處）
//      走 Foundation，綁 Bundle.main，執行中無法改變。
//      解法：在本 module 定義一個「同簽名」的 String(localized:) init。
//      Swift 的多載解析會優先選同 module 的版本，於是所有呼叫點自動改走這裡，
//      呼叫端一行都不用改。內部轉呼叫 Foundation 的多參數版本（簽名不同，不會遞迴），
//      並把 bundle / locale 指到使用者選的語言。
//
//   2. SwiftUI 的 Text("中文") / Section("中文") 等 LocalizedStringKey（約 750 處）
//      這條吃 environment 的 locale，所以在根視圖掛 .environment(\.locale, ...) 即可。
//
// 兩條路徑都已在模擬器上實測驗證過。
//
// 另外要注意：static let 的在地化資料在 process 內只會算一次，切語言後會凍住舊語言。
// 這類資料一律改成 computed var（大表則以語言為 key 做快取），見 Strings.swift、
// ColorPalette.swift 等處。

import Foundation
import SwiftUI

/// 目前生效的在地化來源。
///
/// 會被 String(localized:) 在任意執行緒讀取，但只在主執行緒（設定頁切換語言時）寫入，
/// 且寫入的是不可變的 Bundle / Locale 參考，所以用 nonisolated(unsafe) 是安全的。
enum AppLocalization {

    /// 字串查表用的 bundle（指向某個 .lproj，或 .main 代表跟隨系統）
    nonisolated(unsafe) private(set) static var bundle: Bundle = .main

    /// 日期、數字等格式化用的 locale
    nonisolated(unsafe) private(set) static var locale: Locale = .current

    /// 目前語言的識別字串。快取失效判斷請一律用這個，不要用 Locale.current
    /// —— Locale.current 在 process 內不會因為 App 內切換而改變。
    nonisolated(unsafe) private(set) static var languageID: String = "system"

    /// 啟動時呼叫一次。
    ///
    /// 這時候不需要改 bundle / locale —— AppleLanguages 的覆寫在啟動階段就已經被系統套用，
    /// Bundle.main 與 Locale.current 本來就是對的。要做的只是把 languageID 設成實際生效的語言，
    /// 讓以語言為 key 的快取（色票、應對筆記等）從一開始就有意義的鍵值。
    static func bootstrap() {
        languageID = Bundle.main.preferredLocalizations.first ?? "system"
    }

    /// 套用語言。傳 nil 代表跟隨系統。
    static func apply(languageCode: String?) {
        guard let code = languageCode else {
            bundle = .main
            locale = .current
            languageID = "system"
            return
        }
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let localized = Bundle(path: path) {
            bundle = localized
            locale = Locale(identifier: code)
            languageID = code
        } else {
            // 找不到就退回系統，至少不會整個 App 變成 key 原文
            bundle = .main
            locale = .current
            languageID = "system"
        }
    }

    /// 自我檢查：確認「同簽名遮蔽」這件事真的生效。
    ///
    /// 這個手法依賴 Swift 優先選用同 module 多載的行為。萬一未來的編譯器改變了解析規則，
    /// 呼叫點會靜靜地退回 Foundation 版本 —— 沒有編譯錯誤、沒有當機，只是語言切換默默失效。
    /// 這裡在啟動時主動驗證一次，把「無聲失效」變成看得見的紀錄。
    static func verifyShadowingWorks() {
        guard let jaPath = Bundle.main.path(forResource: "ja", ofType: "lproj"),
              let ja = Bundle(path: jaPath) else { return }

        let saved = (bundle, locale, languageID)
        bundle = ja
        locale = Locale(identifier: "ja")
        let probe = String(localized: "完成")
        (bundle, locale, languageID) = saved

        if probe == "完了" {
            debugLog("✅ AppLocalization：String(localized:) 遮蔽生效")
        } else {
            debugLog("""
                ❌ AppLocalization：String(localized:) 遮蔽失效（取得「\(probe)」，預期「完了」）。
                   App 內切換語言將只會換掉 SwiftUI Text 的部分，其餘停留在舊語言。
                   請檢查 String.init(localized:) 的遮蔽是否仍被編譯器優先選用。
                """)
        }
    }
}

// MARK: - String(localized:) 遮蔽

extension String {
    /// 與 Foundation 的 `String(localized:)` 同簽名，讓同 module 的呼叫點自動改走 App 選定的語言。
    ///
    /// 內部呼叫的是 Foundation 的 `init(localized:bundle:locale:)`（參數不同，不會遞迴）。
    init(localized keyAndValue: String.LocalizationValue) {
        self.init(localized: keyAndValue,
                  bundle: AppLocalization.bundle,
                  locale: AppLocalization.locale)
    }
}
