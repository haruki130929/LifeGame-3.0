import SwiftUI

// MARK: - RingHourLabelsV2

/// Hour labels (0, 3, 6, 9, 12, 15, 18, 21) positioned around the ring.
struct RingHourLabelsV2: View {
    var radius: CGFloat
    var center: CGPoint
    var labelRadius: CGFloat? = nil

    private let hours = [0, 3, 6, 9, 12, 15, 18, 21]

    var body: some View {
        let r = labelRadius ?? (radius + 20)

        ForEach(hours, id: \.self) { hour in
            let minute = hour * 60
            let angle = RingTimeHelpers.angle(for: minute)
            let pos = RingTimeHelpers.point(center: center, radius: r, angle: angle)

            Text("\(hour)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .position(pos)
        }
    }
}
