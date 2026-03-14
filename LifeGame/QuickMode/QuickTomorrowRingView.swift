import SwiftUI

/// Quick Mode 專用：時間圓環上方 + 時段列表下方（垂直佈局）
struct QuickTomorrowRingView: View {
    @EnvironmentObject private var game: LifeGame

    @State private var plan: TomorrowRingPlan = {
        if let saved: TomorrowRingPlan = StorageManager.load(
            TomorrowRingPlan.self, forKey: "tomorrow_ring_plan"
        ) {
            return saved
        }
        return .sample
    }()

    @State private var selectedID: UUID?
    @State private var editingItem: RingItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // ── 圓環 ──
                TomorrowRingView(
                    plan: $plan,
                    selectedItemID: $selectedID,
                    mode: .detail,
                    gameHP: game.hp,
                    gameFP: game.fp
                )
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 12)
                .padding(.top, 8)

                // ── 時段列表 ──
                if plan.items.isEmpty {
                    emptyPlaceholder
                } else {
                    VStack(spacing: 8) {
                        Text("時段")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(plan.items) { item in
                            RingRow(item: item) {
                                editingItem = item
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                }

                Spacer(minLength: 20)
            }
        }
        .onChange(of: plan) { _, newPlan in
            StorageManager.save(newPlan, forKey: "tomorrow_ring_plan")
        }
        .sheet(item: $editingItem) { item in
            EditRingItemSheet(item: item) { updated in
                if let i = plan.items.firstIndex(where: { $0.id == updated.id }) {
                    plan.items[i] = updated
                    plan.items.sort { $0.startMinute < $1.startMinute }
                }
            } onDelete: {
                plan.items.removeAll { $0.id == item.id }
            }
        }
    }

    // MARK: - Empty

    private var emptyPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("還沒有任何時段")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}
