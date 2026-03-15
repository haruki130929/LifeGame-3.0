// File: Core/LifeGame.swift
import Foundation
import Combine
import SwiftUI

@MainActor
final class LifeGame: ObservableObject {
    @Published var hp = Stat(current: 100, max: 100)
    @Published var fp = Stat(current: 100, max: 100)
    @Published var mp = Stat(current: 40, max: 60)
    @Published var equipped: [EquipSlot: EquipItem] = [:]
    
    @Published var startMP: Int = 40 {
        didSet {
            StorageManager.save(startMP, forKey: "game.startMP")
        }
    }
    
    let maxEquipWeight: Int = 10
    
    init() {
        if let saved: Int = StorageManager.load(Int.self, forKey: "game.startMP") {
            self.startMP = saved
        } else {
            self.startMP = 40
        }
    }
    
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
        debugLog("✅ settleToday")
    }

    // MARK: - 時間圓環自動扣除

    private static let deductedKey = "ring_deducted_segments"

    /// 載入今日已扣除的時段 ID
    private func loadDeductedIDs() -> Set<String> {
        guard let saved: [String: [String]] = StorageManager.load([String: [String]].self, forKey: Self.deductedKey) else {
            return []
        }
        let todayKey = Self.todayKey()
        return Set(saved[todayKey] ?? [])
    }

    /// 儲存今日已扣除的時段 ID（只保留今天的紀錄）
    private func saveDeductedIDs(_ ids: Set<String>) {
        let todayKey = Self.todayKey()
        StorageManager.save([todayKey: Array(ids)], forKey: Self.deductedKey)
    }

    private static func todayKey() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    /// 檢查時間圓環的時段，若時段已結束則自動扣除 HP/FP
    func applyRingDeductions(plan: TomorrowRingPlan) {
        let cal = Calendar.current
        let now = Date()
        let currentMinute = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)

        var deducted = loadDeductedIDs()
        var changed = false

        for item in plan.items {
            let idStr = item.id.uuidString
            guard !deducted.contains(idStr) else { continue }

            // 判斷時段是否已結束
            let ended: Bool
            if item.endMinute > item.startMinute {
                // 正常時段（例如 9:00~12:00）
                ended = currentMinute >= item.endMinute
            } else {
                // 跨午夜時段（例如 22:00~02:00），只有到了隔天結束時間之後才算結束
                ended = currentMinute >= item.endMinute && currentMinute < item.startMinute
            }

            if ended {
                hp.add(-item.hpCost)
                fp.add(-item.fpCost)
                deducted.insert(idStr)
                changed = true
                debugLog("⏰ 時段「\(item.title)」結束，HP -\(item.hpCost), FP -\(item.fpCost)")
            }
        }

        if changed {
            saveDeductedIDs(deducted)
        }
    }
}
