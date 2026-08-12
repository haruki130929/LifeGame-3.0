import SwiftUI

/// 每日紀錄「檢視字體大小」設定。
///
/// 用**明確的字級倍率**（`.system(size: 基準 × 倍率)`）縮放，而不是 SwiftUI 的
/// Dynamic Type。因為本 App 在 Mac 上以「Optimize Interface for Mac」（idiom `.mac`）執行，
/// 而 macOS 沒有系統 Dynamic Type，`.dynamicTypeSize` 在 Mac 上不會生效；改用明確倍率可
/// 在 Mac / iPhone / iPad 一致作用。
///
/// 主列表 `DailyLogHistoryView`、檢視 sheet `DailyLogFullReviewCard`、調整面板
/// `DailyLogFontSizeSheet` 綁同一把 `@AppStorage` key（存的是級距索引），改一處立即全同步。
enum DailyLogTextSize {

    /// 三處共用的 UserDefaults key（值為 options 的索引 Int）。
    static let storageKey = "dailyLog.textSizeIndex"

    /// 由小到大的縮放倍率（對應 `labels`，兩者長度必須一致）。
    static let options: [Double] = [0.85, 0.92, 1.0, 1.12, 1.24, 1.40, 1.60]

    /// 給使用者看的級距名稱。
    static var labels: [String] {
        [String(localized: "小"), String(localized: "偏小"), String(localized: "標準"), String(localized: "大"), String(localized: "更大"), String(localized: "特大"), String(localized: "超大")]
    }

    /// 預設級距：Mac Catalyst 視窗大、預設字偏小，預設放大到「更大」（1.24×）；
    /// iPhone / iPad 用「標準」（1.0×，與原本語意字級一致）。
    static var defaultIndex: Int { AppLayout.isMacCatalyst ? 4 : 2 }

    static func clampedIndex(_ i: Int) -> Int { min(max(i, 0), options.count - 1) }

    static func scale(forIndex i: Int) -> Double { options[clampedIndex(i)] }

    static func label(forIndex i: Int) -> String { labels[clampedIndex(i)] }

    /// 依角色基準點級（iOS 標準大小）× 索引對應倍率，回傳實際字體。
    /// 常用基準：headline 17/semibold、body 17、subheadline 15、footnote 13、caption 12。
    static func font(_ base: CGFloat, weight: Font.Weight = .regular, forIndex i: Int) -> Font {
        .system(size: base * scale(forIndex: i), weight: weight)
    }

    /// 已知倍率時直接換算（給用 `@Environment` 傳遞倍率的檢視卡片）。
    static func font(_ base: CGFloat, weight: Font.Weight = .regular, scale: Double) -> Font {
        .system(size: base * scale, weight: weight)
    }
}

// MARK: - Environment：把檢視卡片的字級倍率往下傳，讓 SectionTitle 等子元件自己讀

private struct DailyLogTextScaleKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}

extension EnvironmentValues {
    /// 每日紀錄檢視卡片的字級倍率（1.0 = 標準；匯出 PDF 維持 1.0）。
    var dailyLogTextScale: Double {
        get { self[DailyLogTextScaleKey.self] }
        set { self[DailyLogTextScaleKey.self] = newValue }
    }
}
