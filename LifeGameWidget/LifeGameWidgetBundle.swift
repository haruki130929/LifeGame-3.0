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
        if #available(iOS 16.1, *) {
            TodayStatusLiveActivity()
            TodoLiveActivity()
        }
    }
}
