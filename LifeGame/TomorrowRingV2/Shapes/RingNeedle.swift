import SwiftUI
import Combine

// MARK: - RingNeedle

/// Current time indicator — a red line from center through both rings.
struct RingNeedle: View {
    var center: CGPoint
    var innerRadius: CGFloat
    var outerRadius: CGFloat

    @State private var currentMinute: Int = RingTimeHelpers.minute(from: Date())

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        let angle = RingTimeHelpers.angle(for: currentMinute)
        let tipPoint = RingTimeHelpers.point(center: center, radius: outerRadius + 6, angle: angle)
        let basePoint = RingTimeHelpers.point(center: center, radius: innerRadius - 6, angle: angle)

        Canvas { context, _ in
            var line = Path()
            line.move(to: basePoint)
            line.addLine(to: tipPoint)
            context.stroke(line, with: .color(.red), lineWidth: 1.5)

            // Tip circle
            let tipRect = CGRect(
                x: tipPoint.x - 3, y: tipPoint.y - 3,
                width: 6, height: 6
            )
            context.fill(Path(ellipseIn: tipRect), with: .color(.red))
        }
        .allowsHitTesting(false)
        .onReceive(timer) { _ in
            withAnimation(.linear(duration: 0.5)) {
                currentMinute = RingTimeHelpers.minute(from: Date())
            }
        }
    }
}
