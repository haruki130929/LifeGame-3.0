//
//  LifeGameWidgetBundle.swift
//  LifeGameWidget
//

import WidgetKit
import SwiftUI

@main
struct LifeGameWidgetBundle: WidgetBundle {
    var body: some Widget {
        LifeGameWidget()
        TodoWidget()
        // Live Activities 在 Mac Catalyst 不支援，僅在 iOS/iPadOS 註冊。
        #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
        if #available(iOS 16.1, *) {
            TodayStatusLiveActivity()
            TodoLiveActivity()
        }
        #endif
    }
}
