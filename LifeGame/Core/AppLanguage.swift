// File: Core/AppLanguage.swift
//
// App 內的介面語言切換。
//
// 為什麼是「下次啟動生效」而不是即時切換：
// 這個 App 有約 1,568 處使用 String(localized:)。實測過兩種即時切換手法都不可行——
//   1. 執行中改寫 AppleLanguages：Bundle.main 早已快取住在地化，String(localized:) 完全不受影響。
//   2. Bundle class swizzling：NSLocalizedString / Bundle.localizedString 會跟著變，
//      但 String(localized:) 走的是另一條解析路徑，仍回傳原語言。
// 也就是說即時切換只會換掉一小部分文字，其餘停留在舊語言，比不切換更糟。
// 因此這裡採用寫入 AppleLanguages + 明確告知使用者重新啟動的作法。

import Foundation
import Combine

/// App 支援的介面語言。
enum AppLanguage: String, CaseIterable, Identifiable {
    /// 不覆寫，跟著系統語言走
    case system
    /// 以下 rawValue 必須與 .lproj 目錄名一致，也是寫進 AppleLanguages 的值——請勿更動
    case zhHant = "zh-Hant"
    case english = "en"
    case japanese = "ja"

    var id: String { rawValue }

    /// 語言選單的慣例是各語言用自己的文字呈現，所以只有「跟隨系統」需要在地化。
    var displayName: String {
        switch self {
        case .system:   return String(localized: "跟隨系統")
        case .zhHant:   return "繁體中文"
        case .english:  return "English"
        case .japanese: return "日本語"
        }
    }

    /// 把單一語言代碼對到 App 支援的語言；對不到回傳 nil。
    ///
    /// 必須用前綴比對而不是 AppLanguage(rawValue:)：iOS 的「每個 App 語言」設定寫進來的是
    /// "ja-JP"、"zh-Hant-TW" 這種帶地區碼的值，精確比對會對不到而誤判成「沒有覆寫」。
    static func explicitMatch(for code: String) -> AppLanguage? {
        if code.hasPrefix("zh-Hant") || code.hasPrefix("zh-TW") || code.hasPrefix("zh-HK") {
            return .zhHant
        }
        if code.hasPrefix("ja") { return .japanese }
        if code.hasPrefix("en") { return .english }
        return nil
    }

    /// 把一串系統語言代碼對到 App 支援的語言，全部對不到就退回開發語言。
    static func bestMatch(for codes: [String]) -> AppLanguage {
        for code in codes {
            if let match = explicitMatch(for: code) { return match }
        }
        return .zhHant   // 開發語言
    }
}

/// 管理介面語言偏好。
///
/// 刻意使用 device-local 的 UserDefaults 而非 StorageManager（會同步到 iCloud）：
/// 語言是「這台裝置上想看什麼語言」的偏好，不該把 Mac 的選擇同步到 iPhone。
/// 而且 AppleLanguages 本來就是每台裝置各自的設定。
@MainActor
final class LanguageStore: ObservableObject {

    /// 系統用來決定 App 語言的 key；iOS 內建的「每個 App 語言」設定寫的也是同一個 key，
    /// 所以 App 內切換與系統設定會互相一致。
    private static let appleLanguagesKey = "AppleLanguages"

    @Published var selected: AppLanguage {
        didSet {
            guard selected != oldValue else { return }
            apply(selected)
        }
    }

    init() {
        // 有覆寫就顯示覆寫值，沒有就是「跟隨系統」。
        //
        // 一定要讀「App 自己的 domain」而不是 UserDefaults.standard：standard 會把
        // NSGlobalDomain 合併進來，於是即使使用者沒有做任何覆寫，也會讀到系統語言，
        // 讓選單幾乎永遠停不到「跟隨系統」。App domain 裡的 AppleLanguages 才代表覆寫
        // —— 不論是這個設定頁寫的，或是使用者從 iOS「設定 → LifeGamer → 語言」改的。
        let appDomain = Bundle.main.bundleIdentifier
            .flatMap { UserDefaults.standard.persistentDomain(forName: $0) }
        let override = (appDomain?[Self.appleLanguagesKey] as? [String])?.first
        self.selected = override.flatMap(AppLanguage.explicitMatch(for:)) ?? .system
    }

    /// 目前實際生效的語言代碼，給根視圖當 `.id()` 用：值一變就整棵重建，
    /// 讓已經算好的畫面重新以新語言渲染。
    var viewID: String { AppLocalization.languageID }

    /// 給根視圖的 `.environment(\.locale, ...)`。
    /// SwiftUI 的 `Text("中文")` 這條路徑吃的是 environment 的 locale，
    /// 和 `String(localized:)` 是兩套機制，兩邊都要設才不會半邊沒換。
    var environmentLocale: Locale { AppLocalization.locale }

    private func apply(_ lang: AppLanguage) {
        let defaults = UserDefaults.standard

        switch lang {
        case .system:
            // 移除覆寫，交還給系統語言。
            // 注意：Bundle.main 的在地化在啟動時就決定並快取住了，移除 AppleLanguages
            // 不會讓它「立刻變回系統語言」，所以這裡要明確指到系統語言的 .lproj。
            defaults.removeObject(forKey: Self.appleLanguagesKey)
            AppLocalization.apply(languageCode: Self.systemLanguage().rawValue)
        default:
            defaults.set([lang.rawValue], forKey: Self.appleLanguagesKey)
            AppLocalization.apply(languageCode: lang.rawValue)
        }
    }

    /// 系統本身的語言偏好（忽略 App 自己的覆寫）。
    /// 我們把覆寫寫在 App 自己的 domain，會遮蔽 global domain，
    /// 所以要直接讀 global domain 才拿得到「真正的系統語言」。
    private static func systemLanguage() -> AppLanguage {
        let global = UserDefaults.standard
            .persistentDomain(forName: UserDefaults.globalDomain)?[appleLanguagesKey] as? [String]
        return AppLanguage.bestMatch(for: global ?? Locale.preferredLanguages)
    }
}
