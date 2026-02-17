import SwiftUI

struct TomorrowRingCard: View {
    let size: CardSize
    @Binding var plan: TomorrowRingPlan
    
    var body: some View {
        DashboardCardContainer {
            VStack(alignment: .leading, spacing: 12) {
                CardHeader(title: "TomorrowRing", icon: "clock")
                
                if size == .large {
                    TomorrowRingView(
                        plan: $plan)
                        .frame(height: 260)
                        .frame(maxWidth: .infinity)
                    
                    Divider().opacity(0.35)
                    
                    ScrollView {
                        ringList
                    }
                    .frame(maxHeight: 130) // 讓卡片不爆長
                } else {
                    Text("HP \(plan.remainingHP) / FP \(plan.remainingFP)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
    }
    
    private var ringList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(plan.items) { item in
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color(hex: item.colorHex).opacity(0.9))
                        .frame(width: 8, height: 8)
                    
                    Text(item.title)
                        .font(.footnote)
                        .lineLimit(1)
                    
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.06), lineWidth: 1)
                )
            }
        }
    }
}
