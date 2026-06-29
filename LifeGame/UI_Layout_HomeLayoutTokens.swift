import SwiftUI
import UIKit

// MARK: - Small helpers + iPad 判斷
enum AppLayout {
    static func clamp(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        min(max(v, lo), hi)
    }

    /// 是否在 Mac 上以 Mac Catalyst 執行（在 Mac 視窗中跑的 iPad App）
    static let isMacCatalyst: Bool = {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return false
        #endif
    }()

    /// 是否採用「大版面（iPad / Mac）」而非 iPhone 版面（靜態常數，啟動時決定一次）。
    ///
    /// Mac Catalyst 一律視為 iPad-class：Mac 上 `userInterfaceIdiom` 為 `.mac`，若不特別處理會
    /// 掉進 iPhone 分支（拖曳式 FAB 環、陀螺儀滑卡 quick mode、邊緣滑動手勢），對滑鼠操作很不友善。
    /// 把 Catalyst 當 iPad，可讓 Mac 取得 iPad 版面寬度、點按式 FAB 膠囊選單與 full mode。
    static let isIPad: Bool = {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }()

    /// iPad 元件高度縮放倍率（卡片、圓環、圖表統一使用）
    static let heightScale: CGFloat = isIPad ? 1.15 : 1.0
}

// MARK: - Adaptive Tokens / Rules（跨裝置自適應核心）
enum LayoutTokens {
    // Panel
    static let panelSideInsetMin: CGFloat = 12
    static let panelSideInsetMax: CGFloat = 20
    static let panelMinHeight: CGFloat = 420
    static let panelTopClearance: CGFloat = 12
    static let panelCorner: CGFloat = 26

    // Floating buttons
    static let floatButtonSize: CGFloat = 52
    static let floatTopGap: CGFloat = 8
    static let floatSideGap: CGFloat = 12

    // Tabs leading reserved width
    static var leftTopButtonReservedWidth: CGFloat {
        AppLayout.clamp(floatButtonSize + floatSideGap * 2, 52, 72)
    }
    static let tabsLeadingGap: CGFloat = 6

    // Tabs
    static let tabWidthMin: CGFloat = AppLayout.isIPad ? 110 : 84
    static let tabWidthMax: CGFloat = AppLayout.isIPad ? 160 : 112
    static let tabHeightMin: CGFloat = AppLayout.isIPad ? 38 : 32
    static let tabHeightMax: CGFloat = AppLayout.isIPad ? 50 : 40
    static let tabOverlapMin: CGFloat = 8
    static let tabOverlapMax: CGFloat = 14
    static let tabSlant: CGFloat = 15
    static let tabCorner: CGFloat = 5

    /// 頁籤列高度：HomeMainPanelView 渲染與 HomeContentView 預留上方空間共用，
    /// 確保「面板往下挪的量」與「頁籤往上凸出的量」一致，避免頁籤升到左上/右上按鈕同高。
    static func tabHeight(forContainerWidth containerWidth: CGFloat) -> CGFloat {
        AppLayout.clamp(containerWidth * 0.075, tabHeightMin, tabHeightMax)
    }

    // FAB
    static let fabSideGap: CGFloat = AppLayout.isIPad ? 16 : 20
    static let fabBottomGap: CGFloat = AppLayout.isIPad ? 16 : 20
}

// MARK: - Drawer Panel rules（寬度自適應）
enum DrawerPanel {
    static let overlayDimOpacity: CGFloat = 0.25
    static let drawerHiddenExtra: CGFloat = 20
    static let drawerAnimDuration: CGFloat = 0.4
    static let panelSpring = Animation.spring(response: 0.28, dampingFraction: 0.9)

    static func drawerWidth(for screenWidth: CGFloat) -> CGFloat {
        if AppLayout.isIPad {
            return AppLayout.clamp(screenWidth * 0.25, 260, 320)
        }
        return AppLayout.clamp(screenWidth * 0.42, 260, 340)
    }

    static func rightPanelWidth(for screenWidth: CGFloat) -> CGFloat {
        if AppLayout.isIPad {
            return AppLayout.clamp(screenWidth * 0.50, 400, 560)
        }
        return AppLayout.clamp(screenWidth * 0.55, 360, 520)
    }
}
