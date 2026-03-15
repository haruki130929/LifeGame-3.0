import SwiftUI

/// 根據 FeatureID 導向對應的設定頁面
struct FeatureSettingsRouter: View {
    let feature: FeatureID
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var calendarSettings: CalendarSettingsStore
    @EnvironmentObject private var ringSettings: TomorrowRingSettingsStore

    var body: some View {
        settingsView
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
    }

    @ViewBuilder
    private var settingsView: some View {
        switch feature {
        case .calendar:
            CalendarSettingsView(settings: calendarSettings)
        case .todoQuadrant:
            TodoQuadrantSettingsView()
        case .tomorrowRing:
            TomorrowRingSettingsView(settings: ringSettings)
        case .monthlyScoreCalendar:
            MonthlyScoreSettingsView()
        case .bagRequired:
            BagSettingsView()
        case .dailyLog:
            QuestionModuleSettingsView()
        case .moodThermometer:
            MoodSettingsView()
        case .mandala:
            MandalaSettingsView()
        default:
            SettingsView()
        }
    }
}
