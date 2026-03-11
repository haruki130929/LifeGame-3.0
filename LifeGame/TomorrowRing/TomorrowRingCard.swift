import SwiftUI

struct TomorrowRingCard: View {
    let size: CardSize
    @Binding var plan: TomorrowRingPlan
    @Binding var selectedSegmentID: UUID?
    var onTap: (() -> Void)? = nil

    init(
        size: CardSize,
        plan: Binding<TomorrowRingPlan>,
        selectedSegmentID: Binding<UUID?> = .constant(nil),
        onTap: (() -> Void)? = nil
    ) {
        self.size = size
        self._plan = plan
        self._selectedSegmentID = selectedSegmentID
        self.onTap = onTap
    }

    var body: some View {
        DashboardCardContainer {
            VStack(alignment: .leading, spacing: 12) {
                CardHeader(title: "TomorrowRing", icon: "clock")

                if size == .large {
                    TomorrowRingView(plan: $plan, selectedItemID: $selectedSegmentID)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("HP \(plan.remainingHP) / FP \(plan.remainingFP)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if selectedSegmentID != nil {
                selectedSegmentID = nil
            } else {
                onTap?()
            }
        }
    }
}
