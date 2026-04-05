import Foundation

// MARK: - RingPlanV2

struct RingPlanV2: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var baseHP: Int = 100
    var baseFP: Int = 100
    var planItems: [RingItemV2] = []     // Inner ring: planned
    var actualItems: [RingItemV2] = []   // Outer ring: actual

    // MARK: - HP/FP (computed from actualItems)

    var totalHPCost: Int { actualItems.reduce(0) { $0 + $1.hpCost } }
    var totalFPCost: Int { actualItems.reduce(0) { $0 + $1.fpCost } }
    var remainingHP: Int { max(0, baseHP - totalHPCost) }
    var remainingFP: Int { max(0, baseFP - totalFPCost) }

    // MARK: - Plan HP/FP (for display)

    var plannedHPCost: Int { planItems.reduce(0) { $0 + $1.hpCost } }
    var plannedFPCost: Int { planItems.reduce(0) { $0 + $1.fpCost } }

    // MARK: - Sorted accessors

    var sortedPlanItems: [RingItemV2] {
        planItems.sorted { $0.startMinute < $1.startMinute }
    }

    var sortedActualItems: [RingItemV2] {
        actualItems.sorted { $0.startMinute < $1.startMinute }
    }

    // MARK: - Initialize actual from plan

    /// Copy all planItems into actualItems (preserving IDs for correlation).
    mutating func initializeActual() {
        actualItems = planItems.map { item in
            var copy = item
            copy.id = UUID()
            return copy
        }
    }
}

// MARK: - Sample

extension RingPlanV2 {
    static var sample: RingPlanV2 {
        RingPlanV2(date: Date())
    }
}

// MARK: - Migration from V1

extension RingPlanV2 {
    init(from v1: TomorrowRingPlan) {
        self.id = v1.id
        self.date = v1.date
        self.baseHP = v1.baseHP
        self.baseFP = v1.baseFP
        self.planItems = v1.items.map { RingItemV2(from: $0) }
        self.actualItems = self.planItems.map { item in
            var copy = item
            copy.id = UUID()
            return copy
        }
    }
}
