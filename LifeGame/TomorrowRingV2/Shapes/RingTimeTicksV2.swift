import SwiftUI

// MARK: - RingTimeTicksV2

/// Tick marks every 30 minutes on the outer edge. Major ticks every 60 minutes.
struct RingTimeTicksV2: View {
    var radius: CGFloat
    var center: CGPoint

    private let majorInterval = 60  // every hour
    private let minorInterval = 30  // every 30 min

    var body: some View {
        Canvas { context, _ in
            for minute in stride(from: 0, to: RingTimeHelpers.totalMinutes, by: minorInterval) {
                let isMajor = minute % majorInterval == 0
                let angle = RingTimeHelpers.angle(for: minute)

                let tickLength: CGFloat = isMajor ? 8 : 4
                let tickWidth: CGFloat = isMajor ? 1.5 : 0.8

                let outer = RingTimeHelpers.point(
                    center: center, radius: radius + 4, angle: angle)
                let inner = RingTimeHelpers.point(
                    center: center, radius: radius + 4 - tickLength, angle: angle)

                var path = Path()
                path.move(to: outer)
                path.addLine(to: inner)

                context.stroke(
                    path,
                    with: .color(.primary.opacity(isMajor ? 0.4 : 0.2)),
                    lineWidth: tickWidth
                )
            }
        }
        .allowsHitTesting(false)
    }
}
