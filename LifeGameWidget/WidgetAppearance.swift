//
//  WidgetAppearance.swift
//  LifeGameWidget
//
//  桌面工具的外觀偏好（由 App 設定頁寫進 App Group，widget 讀取）。
//

import SwiftUI
import WidgetKit
import UIKit

enum WidgetAppearance: Int {
    case system = 0
    case light = 1
    case dark = 2

    static func current() -> WidgetAppearance {
        guard let d = UserDefaults(suiteName: "group.com.haruki.lifegame"),
              d.object(forKey: "widget.appearance") != nil else { return .system }
        return WidgetAppearance(rawValue: d.integer(forKey: "widget.appearance")) ?? .system
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

/// 桌面工具的主題表面 —— 對齊 App 內主面板（`HomeMainPanelView`）：
/// ・填色 `panelColor`：深色 = `Color(white: 0.14)`、淺色 = `secondarySystemBackground`。
/// ・細邊框 `panelStroke`：深色 = 白@0.06、淺色 = 黑@0.08。
/// 整片 widget 背景用這個（填色 + 邊框），讓它跟著深／淺「整片」切換、質感和 App 面板一致，
/// 而不是只有文字變色、背景卻停在系統色。
///
/// 註：App 面板還有一層「微陰影」是用來把面板和它底下的根背景分開；widget 是整片到邊的磁貼，
/// 內部沒有底色可投影（外緣分離陰影由系統提供），所以這裡只取「填色 + 邊框」、不畫陰影。
private enum WidgetTheme {
    /// 動態填色：跟隨「目前解析到的外觀」自動切換深／淺。
    static let surface = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.14, alpha: 1)
            : UIColor.secondarySystemBackground.resolvedColor(with: trait)
    }

    /// 動態邊框色，對齊 `HomeMainPanelView.panelStroke`。
    static let stroke = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.06)
            : UIColor.black.withAlphaComponent(0.08)
    }

    /// 背景視圖：填色 + App 面板那種 hairline 細邊框。
    /// `scheme == nil` 代表「跟隨系統」→ 用動態色（由 widget 宿主依主畫面外觀解析）；
    /// 指定 `.light` / `.dark` → 把顏色鎖定成該外觀（固定淺／深色時用）。
    static func background(for scheme: ColorScheme?) -> some View {
        let trait = scheme.map { UITraitCollection(userInterfaceStyle: $0 == .dark ? .dark : .light) }
        let fill = Color(trait.map { surface.resolvedColor(with: $0) } ?? surface)
        let line = Color(trait.map { stroke.resolvedColor(with: $0) } ?? stroke)
        return fill.overlay(
            ContainerRelativeShape().strokeBorder(line, lineWidth: 1)
        )
    }
}

extension View {
    /// 套用使用者選的桌面工具外觀，並讓「背景 + 文字」整片一起切換。
    ///
    /// ⚠️ 為什麼不能只靠 `.environment(\.colorScheme,)`：
    /// Widget 的 `.containerBackground` 材質背景是由 widget 宿主程序依「主畫面的系統
    /// 外觀」算的，**不會**跟著我們覆寫的 `\.colorScheme` 走。只覆寫 colorScheme 的話，
    /// 只有文字／語意色會變，背景仍維持系統色 → 出現「背景維持深色、只有字變淺色」。
    ///
    /// 所以這裡自己用 `containerBackground` 畫 App 的主題表面（填色 + 細邊框）：
    /// ・跟隨系統：用會自動切換的動態色（host 依主畫面外觀解析）。
    /// ・固定淺／深：覆寫 `\.colorScheme`（讓文字／語意色正確）＋ 鎖定對應的表面色。
    @ViewBuilder
    func widgetAppearance() -> some View {
        switch WidgetAppearance.current() {
        case .system:
            self.containerBackground(for: .widget) {
                WidgetTheme.background(for: nil)
            }
        case .light:
            self
                .environment(\.colorScheme, .light)
                .containerBackground(for: .widget) {
                    WidgetTheme.background(for: .light)
                }
        case .dark:
            self
                .environment(\.colorScheme, .dark)
                .containerBackground(for: .widget) {
                    WidgetTheme.background(for: .dark)
                }
        }
    }
}
