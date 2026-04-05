import SwiftUI

// MARK: - RingCardV2

/// Dashboard card wrapping the dual ring in the standard card container.
struct RingCardV2: View {
    @EnvironmentObject private var store: TomorrowRingStore

    var size: CardSize = .large
    var onTap: (() -> Void)? = nil

    @State private var selectedItemID: UUID?

    var body: some View {
        DashboardCardContainer {
            VStack(alignment: .leading, spacing: 12) {
                CardHeader(title: "時間圓環", icon: "clock")

                if size == .large {
                    DualRingCanvas(mode: .card, selectedItemID: $selectedItemID)
                        .frame(height: 200 * AppLayout.heightScale)
                        .frame(maxWidth: .infinity)
                } else {
                    HStack(spacing: 12) {
                        Label("\(store.plan.remainingHP)", systemImage: "heart.fill")
                            .foregroundStyle(.red)
                        Label("\(store.plan.remainingFP)", systemImage: "flame.fill")
                            .foregroundStyle(.orange)
                    }
                    .font(.caption)
                    .monospacedDigit()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if selectedItemID != nil {
                selectedItemID = nil
            } else {
                onTap?()
            }
        }
    }
}
