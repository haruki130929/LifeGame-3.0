import SwiftUI

struct TomorrowRingDetailView: View {
    @Binding var plan: TomorrowRingPlan
    
    @State private var isPresentingAdd = false
    @State private var isRingInteracting = false
    
    // ✅ 控制 + 選單（用 Menu 的話不需要 state）
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    
                    // 1) 最上面：同一個時間圓環（資訊跟 card 一樣）
                    TomorrowRingView(plan: $plan, isInteracting: $isRingInteracting)
                        .frame(height: 260)
                        .frame(maxWidth: .infinity)
                    
                    Divider().opacity(0.35)
                    
                    // 3) 圓環下面：列舉各時段（顏色點、事情、時間總長）
                    VStack(alignment: .leading, spacing: 10) {
                        Text("時段")
                            .font(.headline)
                        
                        ForEach(plan.items) { item in
                            RingRow(item: item)
                        }
                    }
                }
            }
            .scrollDisabled(isRingInteracting)
        }
        .navigationTitle("TomorrowRing")
        .navigationBarTitleDisplayMode(.inline)
        
        .sheet(isPresented: $isPresentingAdd) {
            AddRingItemSheet(defaultStartMinute: defaultNewStartMinute()) { draft in
                let new = RingItem(
                    id: UUID(),
                    slot: draft.slot,
                    startMinute: draft.startMinute,
                    endMinute: draft.endMinute,
                    title: draft.title,
                    icon: draft.icon,
                    colorHex: draft.colorHex,
                    hpCost: draft.hpCost,
                    fpCost: draft.fpCost
                )
                plan.items.append(new)
                // 讓列表順一點（可留可不留）
                plan.items.sort { $0.startMinute < $1.startMinute }
            }
        }
    }
    private func defaultNewStartMinute() -> Int {
        let fallback = 9 * 60
        guard let last = plan.items.max(by: { $0.endMinute < $1.endMinute }) else { return fallback }
        return last.endMinute
    }
}

private struct RingRow: View {
    let item: RingItem
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: item.colorHex).opacity(0.9))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.footnote)
                    .lineLimit(1)
                
                Text("\(minuteText(item.startMinute)) 〜 \(minuteText(item.endMinute))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
            
            Text(durationText(start: item.startMinute, end: item.endMinute))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    private func durationText(start: Int, end: Int) -> String {
        let total = positiveDuration(from: start, to: end) // 分鐘
        let h = total / 60
        let m = total % 60
        if h > 0 {
            return String(format: "%dh %02dm", h, m)
        } else {
            return String(format: "%dm", m)
        }
    }
    
    private func positiveDuration(from start: Int, to end: Int) -> Int {
        let totalMinutes = 1440
        let d = end - start
        return d >= 0 ? d : (d + totalMinutes)
    }
    
    private func minuteText(_ m: Int) -> String {
        let mm = (m % 1440 + 1440) % 1440
        let h = mm / 60
        let min = mm % 60
        return String(format: "%02d:%02d", h, min)
    }
}
