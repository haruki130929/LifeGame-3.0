// File: Equipment/EquipmentModels.swift
import Foundation

enum EquipSlot: String, CaseIterable, Identifiable, Codable, Hashable {
    case head = "頭飾"
    case hand = "手飾"
    case action = "行動物品"
    case care = "保養品"
    case comfort = "隨身小物"
    var id: String { rawValue }
}

enum EquipEffect: Codable, Hashable {
    case mpMax(Int)
    case weight(Int)
    
    enum Kind: String, CaseIterable, Identifiable {
        case mpMax = "增加 MP 上限"
        case weight = "增加重量"
        var id: String { rawValue }
    }
    
    var kind: Kind {
        switch self {
        case .mpMax: return .mpMax
        case .weight: return .weight
        }
    }
    
    var value: Int {
        switch self {
        case .mpMax(let v): return v
        case .weight(let v): return v
        }
    }
    
    var displayText: String {
        switch self {
        case .mpMax(let v): return "MP 上限 +\(v)"
        case .weight(let v): return "重量 +\(v)"
        }
    }
    
    private enum CodingKeys: String, CodingKey { case type, value }
    private enum EffectType: String, Codable { case mpMax, weight }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(EffectType.self, forKey: .type)
        let value = try c.decode(Int.self, forKey: .value)
        switch type {
        case .mpMax: self = .mpMax(value)
        case .weight: self = .weight(value)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .mpMax(let v):
            try c.encode(EffectType.mpMax, forKey: .type)
            try c.encode(v, forKey: .value)
        case .weight(let v):
            try c.encode(EffectType.weight, forKey: .type)
            try c.encode(v, forKey: .value)
        }
    }
}

struct EquipItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var slot: EquipSlot
    var name: String
    var note: String = ""
    var effects: [EquipEffect] = []
}

let sampleItems: [EquipItem] = [
    EquipItem(slot: .head, name: "耳環", note: "亮亮的", effects: [.mpMax(5), .weight(2)]),
    EquipItem(slot: .hand, name: "手錶", note: "提醒時間", effects: [.mpMax(3), .weight(2)]),
    EquipItem(slot: .action, name: "手帳本", note: "更有掌控感", effects: [.mpMax(5), .weight(2)]),
    EquipItem(slot: .care, name: "護手霜", note: "手舒服", effects: [.mpMax(2), .weight(2)]),
    EquipItem(slot: .comfort, name: "耳塞", note: "降噪", effects: [.mpMax(4), .weight(2)])
]
