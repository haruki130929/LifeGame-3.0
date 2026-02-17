// File: Core/LifeGame.swift
import Foundation
import SwiftUI

final class LifeGame: ObservableObject {
    @Published var hp = Stat(current: 100, max: 100)
    @Published var fp = Stat(current: 100, max: 100)
    @Published var mp = Stat(current: 40, max: 60)
    @Published var equipped: [EquipSlot: EquipItem] = [:]
    @AppStorage("game.startMP") var startMP: Int = 40
    
    let maxEquipWeight: Int = 10
    
    func weight(of item: EquipItem) -> Int {
        for e in item.effects {
            if case .weight(let v) = e { return v }
        }
        return 2
    }
    
    var totalEquipWeight: Int {
        equipped.values.reduce(0) { $0 + weight(of: $1) }
    }
    
    func canEquip(_ item: EquipItem, to slot: EquipSlot) -> Bool {
        let current = totalEquipWeight
        let removing = equipped[slot].map { weight(of: $0) } ?? 0
        let adding = weight(of: item)
        return (current - removing + adding) <= maxEquipWeight
    }
    
    func attendClass() {
        hp.add(-10)
        fp.add(-10)
    }
    
    func addMP(unit: Int) {
        mp.add(unit * 5)
    }
    
    func resetForNewDay() {
        hp.current = hp.max
        fp.current = fp.max
        mp.current = min(startMP, mp.max)
    }
    
    var mpProgress: Double {
        Double(mp.current) / Double(mp.max)
    }
    
    func settleToday(into history: HistoryStore) {
        let record = DayRecord.make(date: Date(), hp: hp.current, fp: fp.current, mp: mp.current)
        history.upsert(record: record)
    }
}

extension LifeGame {
    
    /// 一堂課：HP -10、FP -10（不動 MP）
    func applyClassCost() {
        hp.current = max(0, hp.current - 10)
        fp.current = max(0, fp.current - 10)
    }
    
    /// 今日結算：先做最小可用版本（之後要接 HistoryStore 再擴充）
    func settleToday() {
        // 先留著：之後可以在這裡寫「把今日狀態寫進回顧 / 歷史」
        // 例如：history.add(...)
        print("✅ settleToday")
    }
}
