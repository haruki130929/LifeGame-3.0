import SwiftUI

struct TomorrowRingCard: View {
    let size: CardSize
    @Binding var plan: TomorrowRingPlan
    @Binding var selectedSegmentID: UUID?
    var onTap: (() -> Void)? = nil

    @EnvironmentObject private var game: LifeGame

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
                CardHeader(title: "時間圓環", icon: "clock")

                if size == .large {
                    TomorrowRingView(
                        plan: $plan,
                        selectedItemID: $selectedSegmentID,
                        gameHP: game.hp,
                        gameFP: game.fp
                    )
                    .frame(height: 200 * AppLayout.heightScale)
                    .frame(maxWidth: .infinity)
                } else {
                    Text("HP \(game.hp.current)/\(game.hp.max)  FP \(game.fp.current)/\(game.fp.max)")
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
