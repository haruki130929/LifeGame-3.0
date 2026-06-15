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

        /// 自訂解碼：跳過未知的 CardType（向後相容）
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            beforeLeave    = (try? [CardItem](safeDecoding: container.superDecoder(forKey: .beforeLeave))) ?? []
            morning        = (try? [CardItem](safeDecoding: container.superDecoder(forKey: .morning))) ?? []
            earlyAfternoon = (try? [CardItem](safeDecoding: container.superDecoder(forKey: .earlyAfternoon))) ?? []
            beforeEnd      = (try? [CardItem](safeDecoding: container.superDecoder(forKey: .beforeEnd))) ?? []
            bedtime        = (try? [CardItem](safeDecoding: container.superDecoder(forKey: .bedtime))) ?? []
        }

        init(beforeLeave: [CardItem], morning: [CardItem], earlyAfternoon: [CardItem], beforeEnd: [CardItem], bedtime: [CardItem]) {
            self.beforeLeave = beforeLeave
            self.morning = morning
            self.earlyAfternoon = earlyAfternoon
            self.beforeEnd = beforeEnd
            self.bedtime = bedtime
        }
    }

    @Published private(set) var config: Config {
        didSet { if !isReloading { save() } }
    }

    private let key = "slot_card_config_v5"  // v5：睡前加入本月結算
    private var syncHelper: StoreSyncHelper?
    private var isReloading = false

    // MARK: - Init

    init() {
        let initialConfig: Config

        if let decoded: Config = StorageManager.load(Config.self, forKey: key) {
            // 已有資料 → 直接用，完整保留使用者自訂的卡片配置「與尺寸」
            initialConfig = decoded
        } else {
            // 全新安裝 → 使用預設值
            initialConfig = Self.makeDefaults()
        }

        self.config = initialConfig

        debugLog("✅ SlotCardConfigStore init (v4 – 5 slots)")
        debugLog("beforeLeave types:", config.beforeLeave.map { $0.type.rawValue })
        debugLog("morning types:", config.morning.map { $0.type.rawValue })

        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    // MARK: - Cross-device Sync

    func reloadFromStorage() {
        isReloading = true
        defer { isReloading = false }
        if let decoded: Config = StorageManager.load(Config.self, forKey: key) {
            config = decoded
        }
    }

    // MARK: - 預設卡片配置

    private static func makeDefaults() -> Config {
        func d(_ types: [CardType]) -> [CardItem] {
            types.map { CardItem(type: $0, size: $0.defaultSize) }
        }

        return Config(
            beforeLeave:    d([.bagRequired, .todoQuadrant, .tomorrowRing, .calendar, .copingNotes]),
            morning:        d([.todoQuadrant, .tomorrowRing, .calendar]),
            earlyAfternoon: d([.todoQuadrant, .tomorrowRing, .calendar]),
            beforeEnd:      d([.todoQuadrant, .tomorrowRing, .calendar]),
            bedtime:        d([.todoQuadrant, .tomorrowRing, .calendar, .bagRequired, .monthlyScoreCalendar])
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

    // MARK: - Save

    private func save() {
        StorageManager.save(config, forKey: key)
    }
}
