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

    private let key = "slot_card_config_v4"  // v4：重新設定預設卡片

    // MARK: - Init

    init() {
        let initialConfig: Config

        if let decoded: Config = StorageManager.load(Config.self, forKey: key) {
            // 已有 v4 資料 → 直接用（保留使用者自訂的卡片配置）
            var fixed = decoded
            fixed.beforeLeave    = Self.forceCalendarLarge(fixed.beforeLeave)
            fixed.morning        = Self.forceCalendarLarge(fixed.morning)
            fixed.earlyAfternoon = Self.forceCalendarLarge(fixed.earlyAfternoon)
            fixed.beforeEnd      = Self.forceCalendarLarge(fixed.beforeEnd)
            fixed.bedtime        = Self.forceCalendarLarge(fixed.bedtime)
            initialConfig = fixed

        } else {
            // v3、v2 或全新安裝 → 一律使用新預設值
            initialConfig = Self.makeDefaults()
        }

        self.config = initialConfig

        debugLog("✅ SlotCardConfigStore init (v4 – 5 slots)")
        debugLog("beforeLeave types:", config.beforeLeave.map { $0.type.rawValue })
        debugLog("morning types:", config.morning.map { $0.type.rawValue })
    }

    // MARK: - 預設卡片配置

    private static func makeDefaults() -> Config {
        func d(_ types: [CardType]) -> [CardItem] {
            types.map { CardItem(type: $0, size: $0.defaultSize) }
        }

        return Config(
            beforeLeave:    d([.bagRequired, .todoQuadrant, .tomorrowRing, .calendar]),
            morning:        d([.todoQuadrant, .tomorrowRing, .calendar]),
            earlyAfternoon: d([.todoQuadrant, .tomorrowRing, .calendar]),
            beforeEnd:      d([.todoQuadrant, .tomorrowRing, .calendar]),
            bedtime:        d([.todoQuadrant, .tomorrowRing, .calendar, .bagRequired])
        )
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

    // MARK: - Helpers

    private static func forceCalendarLarge(_ items: [CardItem]) -> [CardItem] {
        items.map { item in
            var copy = item
            if copy.type == .calendar { copy.size = .large }
            return copy
        }
    }

    // MARK: - Save

    private func save() {
        StorageManager.save(config, forKey: key)
    }
}
