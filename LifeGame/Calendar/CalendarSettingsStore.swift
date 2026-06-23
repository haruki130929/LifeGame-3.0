import Foundation
import Combine
import SwiftUI

/// 顏色對應的固定行程名稱
struct EventColorPreset: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var colorHex: String
    var name: String
}

@MainActor
final class CalendarSettingsStore: ObservableObject {
    private enum Keys {
        static let firstWeekday = "calendar_firstWeekday"
        static let syncAppleCalendar = "calendar_syncAppleCalendar"
        static let colorPresets = "calendar_colorPresets"
        static let eventFontScale = "calendar_eventFontScale"
    }

    /// 1=週日, 2=週一...7=週六（預設週日）
    @Published var firstWeekday: Int = 1 {
        didSet {
            if !isReloading { StorageManager.save(firstWeekday, forKey: Keys.firstWeekday) }
        }
    }

    /// 是否同步 Apple 內建行事曆
    @Published var syncAppleCalendar: Bool = false {
        didSet {
            if !isReloading { StorageManager.save(syncAppleCalendar, forKey: Keys.syncAppleCalendar) }
        }
    }

    /// 顏色代表行程（色碼 → 固定行程名稱）
    @Published var colorPresets: [EventColorPreset] = [] {
        didSet {
            if !isReloading { StorageManager.save(colorPresets, forKey: Keys.colorPresets) }
        }
    }

    /// 功能頁月曆上「行程名稱」的字級倍率（1.0 ~ 1.8）
    @Published var eventFontScale: Double = 1.25 {
        didSet {
            if !isReloading { StorageManager.save(eventFontScale, forKey: Keys.eventFontScale) }
        }
    }

    private var syncHelper: StoreSyncHelper?
    private var isReloading = false

    init() {
        firstWeekday = StorageManager.load(Int.self, forKey: Keys.firstWeekday) ?? 1
        syncAppleCalendar = StorageManager.load(Bool.self, forKey: Keys.syncAppleCalendar) ?? false
        colorPresets = StorageManager.load([EventColorPreset].self, forKey: Keys.colorPresets) ?? []
        eventFontScale = StorageManager.load(Double.self, forKey: Keys.eventFontScale) ?? 1.25
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    func reloadFromStorage() {
        isReloading = true
        defer { isReloading = false }
        firstWeekday = StorageManager.load(Int.self, forKey: Keys.firstWeekday) ?? 1
        syncAppleCalendar = StorageManager.load(Bool.self, forKey: Keys.syncAppleCalendar) ?? false
        colorPresets = StorageManager.load([EventColorPreset].self, forKey: Keys.colorPresets) ?? []
        eventFontScale = StorageManager.load(Double.self, forKey: Keys.eventFontScale) ?? 1.25
    }

    var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "zh_TW")
        cal.timeZone = .current
        cal.firstWeekday = firstWeekday
        return cal
    }

    /// 根據顏色找到對應的行程名稱
    func presetName(for hex: String) -> String? {
        colorPresets.first { $0.colorHex.uppercased() == hex.uppercased() }?.name
    }
}
