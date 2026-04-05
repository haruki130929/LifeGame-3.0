import SwiftUI

// MARK: - ArcShapeV2

/// Solid arc segment for filled time slots. Supports midnight wrap.
struct ArcShapeV2: Shape {
    var startMinute: Int
    var endMinute: Int

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(Double(startMinute), Double(endMinute)) }
        set {
            startMinute = Int(newValue.first)
            endMinute = Int(newValue.second)
        }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        let startAngle = Angle(radians: RingTimeHelpers.angle(for: startMinute) - .pi / 2)
        let endAngle = Angle(radians: RingTimeHelpers.angle(for: endMinute) - .pi / 2)

        var path = Path()

        if startMinute <= endMinute {
            path.addArc(center: center, radius: radius,
                        startAngle: startAngle, endAngle: endAngle,
                        clockwise: false)
        } else {
            // Wrap midnight: draw in one continuous arc (clockwise: false still works
            // because endAngle < startAngle in absolute terms)
            path.addArc(center: center, radius: radius,
                        startAngle: startAngle, endAngle: endAngle,
                        clockwise: false)
        }

        return path
    }
}
