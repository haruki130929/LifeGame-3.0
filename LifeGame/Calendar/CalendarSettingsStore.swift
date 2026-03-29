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
    }

    /// 1=週日, 2=週一...7=週六（預設週日）
    @Published var firstWeekday: Int = 1 {
        didSet {
            StorageManager.save(firstWeekday, forKey: Keys.firstWeekday)
        }
    }

    /// 是否同步 Apple 內建行事曆
    @Published var syncAppleCalendar: Bool = false {
        didSet {
            StorageManager.save(syncAppleCalendar, forKey: Keys.syncAppleCalendar)
        }
    }

    /// 顏色代表行程（色碼 → 固定行程名稱）
    @Published var colorPresets: [EventColorPreset] = [] {
        didSet {
            StorageManager.save(colorPresets, forKey: Keys.colorPresets)
        }
    }

    init() {
        firstWeekday = StorageManager.load(Int.self, forKey: Keys.firstWeekday) ?? 1
        syncAppleCalendar = StorageManager.load(Bool.self, forKey: Keys.syncAppleCalendar) ?? false
        colorPresets = StorageManager.load([EventColorPreset].self, forKey: Keys.colorPresets) ?? []
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
