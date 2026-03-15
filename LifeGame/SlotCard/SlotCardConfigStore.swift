import SwiftUI
import Combine
import Foundation

@MainActor
final class SlotCardConfigStore: ObservableObject {

    // MARK: - Config（5 個時段）

    struct Config: Codable {
        var beforeLeave: [CardItem]
        var morning: [CardItem]
        var earlyAfternoon: [CardItem]
        var beforeEnd: [CardItem]
        var bedtime: [CardItem]
    }

    @Published private(set) var config: Config {
        didSet { save() }
    }

    private let key = "slot_card_config_v3"         // v3：5 時段
    private let legacyKey = "slot_card_config_v2"    // v2：舊 4 時段

    // MARK: - Init

    init() {
        let initialConfig: Config

        if let decoded: Config = StorageManager.load(Config.self, forKey: key) {
            // 已有 v3 資料 → 直接用
            var fixed = decoded
            fixed.beforeLeave    = Self.forceCalendarLarge(fixed.beforeLeave)
            fixed.morning        = Self.forceCalendarLarge(fixed.morning)
            fixed.earlyAfternoon = Self.forceCalendarLarge(fixed.earlyAfternoon)
            fixed.beforeEnd      = Self.forceCalendarLarge(fixed.beforeEnd)
            fixed.bedtime        = Self.forceCalendarLarge(fixed.bedtime)
            initialConfig = Self.migrateIfNeeded(fixed)

        } else if let legacy = Self.loadLegacy(forKey: "slot_card_config_v2") {
            // 有舊 v2 資料 → 遷移到 5 時段
            initialConfig = Self.migrateIfNeeded(Self.migrateFromV2(legacy))

        } else {
            // 全新安裝
            func defaults(_ types: [CardType]) -> [CardItem] {
                types.map { CardItem(type: $0, size: $0.defaultSize) }
            }

            let base = Config(
                beforeLeave:    defaults([.tomorrowRing, .bagRequired, .editCards]),
                morning:        defaults([.calendar, .dailyLog, .editCards]),
                earlyAfternoon: defaults([.calendar, .dailyLog, .editCards]),
                beforeEnd:      defaults([.dailyLog, .editCards]),
                bedtime:        defaults([.dailyLog, .editCards])
            )
            initialConfig = Self.migrateIfNeeded(base)
        }

        self.config = initialConfig

        debugLog("✅ SlotCardConfigStore init (v3 – 5 slots)")
        debugLog("beforeLeave types:", config.beforeLeave.map { $0.type.rawValue })
        debugLog("morning types:", config.morning.map { $0.type.rawValue })
    }

    // MARK: - Public API

    func items(for slot: TimeSlot) -> [CardItem] {
        switch slot {
        case .beforeLeave:    return config.beforeLeave
        case .morning:        return config.morning
        case .earlyAfternoon: return config.earlyAfternoon
        case .beforeEnd:      return config.beforeEnd
        case .bedtime:        return config.bedtime
        }
    }

    func setItems(_ items: [CardItem], for slot: TimeSlot) {
        switch slot {
        case .beforeLeave:    config.beforeLeave = items
        case .morning:        config.morning = items
        case .earlyAfternoon: config.earlyAfternoon = items
        case .beforeEnd:      config.beforeEnd = items
        case .bedtime:        config.bedtime = items
        }
    }

    // MARK: - Helpers (全部 static，避免 init 早期用到 self)

    private static func forceCalendarLarge(_ items: [CardItem]) -> [CardItem] {
        items.map { item in
            var copy = item
            if copy.type == .calendar { copy.size = .large }
            return copy
        }
    }

    // MARK: - Legacy V2 (4 時段) 讀取

    private struct LegacyConfig: Codable {
        var morning: [CardItem]
        var afternoon: [CardItem]
        var evening: [CardItem]
        var night: [CardItem]
    }

    private static func loadLegacy(forKey key: String) -> LegacyConfig? {
        StorageManager.load(LegacyConfig.self, forKey: key)
    }

    /// 將舊 4 時段對應到新 5 時段
    /// morning   → morning
    /// afternoon → earlyAfternoon
    /// evening   → beforeEnd
    /// night     → bedtime
    /// beforeLeave 給預設值
    private static func migrateFromV2(_ legacy: LegacyConfig) -> Config {
        func defaults(_ types: [CardType]) -> [CardItem] {
            types.map { CardItem(type: $0, size: $0.defaultSize) }
        }

        return Config(
            beforeLeave:    defaults([.tomorrowRing, .bagRequired, .editCards]),
            morning:        legacy.morning,
            earlyAfternoon: legacy.afternoon,
            beforeEnd:      legacy.evening,
            bedtime:        legacy.night
        )
    }

    // MARK: - Migration（補 todoQuadrant + tomorrowPlan 等必要卡片）

    private static func migrateIfNeeded(_ cfg: Config) -> Config {
        var c = cfg
        let targetSlots: [TimeSlot] = TimeSlot.allCases

        for slot in targetSlots {
            var items = Self.items(in: c, slot: slot)

            // 補 todoQuadrant
            if !items.contains(where: { $0.type == .todoQuadrant }) {
                items.append(CardItem(type: .todoQuadrant, size: .large))
            }

            // 補 monthlyScoreCalendar（本月結算）
            if !items.contains(where: { $0.type == .monthlyScoreCalendar }) {
                if let calendarIndex = items.firstIndex(where: { $0.type == .calendar }) {
                    let insertIndex = min(calendarIndex + 1, items.count)
                    items.insert(CardItem(type: .monthlyScoreCalendar, size: .large), at: insertIndex)
                } else {
                    items.append(CardItem(type: .monthlyScoreCalendar, size: .large))
                }
            }

            // 補 tomorrowPlan
            if !items.contains(where: { $0.type == .tomorrowRing }) {
                items.insert(CardItem(type: .tomorrowRing, size: .large), at: 0)
            }

            // 補 bagRequired（整理書包：只顯示必帶）
            if !items.contains(where: { $0.type == .bagRequired }) {
                let insertIndex = min(1, items.count)
                items.insert(CardItem(type: .bagRequired, size: .medium), at: insertIndex)
            }

            Self.setItems(in: &c, slot: slot, items: items)
        }

        return c
    }

    private static func items(in c: Config, slot: TimeSlot) -> [CardItem] {
        switch slot {
        case .beforeLeave:    return c.beforeLeave
        case .morning:        return c.morning
        case .earlyAfternoon: return c.earlyAfternoon
        case .beforeEnd:      return c.beforeEnd
        case .bedtime:        return c.bedtime
        }
    }

    private static func setItems(in c: inout Config, slot: TimeSlot, items: [CardItem]) {
        switch slot {
        case .beforeLeave:    c.beforeLeave = items
        case .morning:        c.morning = items
        case .earlyAfternoon: c.earlyAfternoon = items
        case .beforeEnd:      c.beforeEnd = items
        case .bedtime:        c.bedtime = items
        }
    }

    // MARK: - Save

    private func save() {
        StorageManager.save(config, forKey: key)
    }
}
