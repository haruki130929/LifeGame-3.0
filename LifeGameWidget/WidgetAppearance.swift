//
//  WidgetAppearance.swift
//  LifeGameWidget
//
//  桌面工具的外觀偏好（由 App 設定頁寫進 App Group，widget 讀取）。
//

import SwiftUI

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

extension View {
    /// 套用使用者選的桌面工具外觀；選「跟隨系統」時不覆寫。
    /// 需放在最外層（containerBackground 之後），才會連背景一起套色。
    @ViewBuilder
    func widgetAppearance() -> some View {
        if let scheme = WidgetAppearance.current().colorScheme {
            self.environment(\.colorScheme, scheme)
        } else {
            self
        }
    }
}
