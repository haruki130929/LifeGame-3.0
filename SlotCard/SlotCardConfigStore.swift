import SwiftUI
import Foundation

final class SlotCardConfigStore: ObservableObject {
    
    struct Config: Codable {
        var morning: [CardItem]
        var afternoon: [CardItem]
        var evening: [CardItem]
        var night: [CardItem]
    }
    
    @Published private(set) var config: Config {
        didSet { save() }
    }
    
    private let key = "slot_card_config_v2"
    
    init() {
        
        let initialConfig: Config
        
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Config.self, from: data) {
            
            var fixed = decoded
            fixed.morning = Self.forceCalendarLarge(fixed.morning)
            fixed.afternoon = Self.forceCalendarLarge(fixed.afternoon)
            fixed.evening = Self.forceCalendarLarge(fixed.evening)
            fixed.night = Self.forceCalendarLarge(fixed.night)
            
            // ✅ 重要：補上 todoQuadrant（如果還沒出現過）
            initialConfig = Self.migrateIfNeeded(fixed)
            
        } else {
            
            func defaults(_ types: [CardType]) -> [CardItem] {
                types.map { CardItem(type: $0, size: $0.defaultSize) }
            }
            
            let base = Config(
                morning: defaults([.quickStart, .todayStatus, .calendar, .dailyLog, .editCards]),
                afternoon: defaults([.todayStatus, .calendar, .dailyLog, .editCards]),
                evening: defaults([.todayStatus, .dailyLog, .editCards]),
                night: defaults([.todayStatus, .dailyLog, .editCards])
            )
            
            // ✅ 重要：新安裝也要補 todoQuadrant
            initialConfig = Self.migrateIfNeeded(base)
        }
        
        // ✅ 到這裡才第一次碰 self
        self.config = initialConfig
        
        print("✅ SlotCardConfigStore init")
        print("morning types:", config.morning.map { $0.type.rawValue })
    }
    
    func items(for slot: TimeSlot) -> [CardItem] {
        switch slot {
        case .morning: return config.morning
        case .afternoon: return config.afternoon
        case .evening: return config.evening
        case .night: return config.night
        }
    }
    
    func setItems(_ items: [CardItem], for slot: TimeSlot) {
        switch slot {
        case .morning: config.morning = items
        case .afternoon: config.afternoon = items
        case .evening: config.evening = items
        case .night: config.night = items
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
    
    // MARK: - Migration（補 todoQuadrant + tomorrowPlan）
    private static func migrateIfNeeded(_ cfg: Config) -> Config {
        var c = cfg
        let targetSlots: [TimeSlot] = [.morning, .afternoon, .evening, .night]
        
        for slot in targetSlots {
            var items = Self.items(in: c, slot: slot)
            
            // ✅ 補 todoQuadrant
            if !items.contains(where: { $0.type == .todoQuadrant }) {
                items.append(CardItem(type: .todoQuadrant, size: .large))
            }
            
            // ✅ 補 tomorrowPlan
            if !items.contains(where: { $0.type == .tomorrowRing }) {
                // 放在比較前面會比較像「一進來先看到」
                // 想放最前面：insert at 0
                items.insert(CardItem(type: .tomorrowRing, size: .large), at: 0)
            }
            
            // ✅ 補 bagRequired（收拾書包：只顯示必帶）
            if !items.contains(where: { $0.type == .bagRequired }) {
                // 建議放在 tomorrowRing 後面（index 1），看起來像「先排時間→再看必帶物品」
                let insertIndex = min(1, items.count)
                items.insert(CardItem(type: .bagRequired, size: .medium), at: insertIndex)
            }
            
            Self.setItems(in: &c, slot: slot, items: items)
        }
        
        return c
    }
    
    private static func items(in c: Config, slot: TimeSlot) -> [CardItem] {
        switch slot {
        case .morning: return c.morning
        case .afternoon: return c.afternoon
        case .evening: return c.evening
        case .night: return c.night
        }
    }
    
    private static func setItems(in c: inout Config, slot: TimeSlot, items: [CardItem]) {
        switch slot {
        case .morning: c.morning = items
        case .afternoon: c.afternoon = items
        case .evening: c.evening = items
        case .night: c.night = items
        }
    }
    
    // MARK: - Save
    
    private func save() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
