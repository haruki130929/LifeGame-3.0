import SwiftUI

// MARK: - DashedArcOutline

/// Hollow capsule-shaped outline for empty time slots.
/// Builds a single closed path (outer arc + end cap + inner arc + start cap)
/// so a single dashed stroke flows continuously around the capsule perimeter.
struct DashedArcOutline: View {
    var startMinute: Int
    var endMinute: Int
    var baseRadius: CGFloat
    var bandWidth: CGFloat
    var color: Color = .primary.opacity(0.28)
    var lineWidth: CGFloat = 1.5

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            CapsuleOutlinePath(
                startMinute: startMinute,
                endMinute: endMinute,
                baseRadius: baseRadius,
                bandWidth: bandWidth,
                center: center
            )
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .butt,
                    lineJoin: .round,
                    dash: [3, 5]
                )
            )
        }
        .allowsHitTesting(false)
    }
}

// MARK: - CapsuleOutlinePath

private struct CapsuleOutlinePath: Shape {
    var startMinute: Int
    var endMinute: Int
    var baseRadius: CGFloat
    var bandWidth: CGFloat
    var center: CGPoint

    func path(in rect: CGRect) -> Path {
        let outerR = baseRadius + bandWidth / 2
        let innerR = baseRadius - bandWidth / 2
        let capRadius = bandWidth / 2

        // Normalize angles so endRad > startRad
        var startRad = RingTimeHelpers.angle(for: startMinute) - .pi / 2
        var endRad = RingTimeHelpers.angle(for: endMinute) - .pi / 2
        while endRad <= startRad {
            endRad += 2 * .pi
        }

        // Full circle case (no items): draw outer + inner as separate circles
        let isFullCircle = (endRad - startRad) >= (2 * .pi - 0.001)
        if isFullCircle {
            var path = Path()
            path.addEllipse(in: CGRect(
                x: center.x - outerR, y: center.y - outerR,
                width: outerR * 2, height: outerR * 2
            ))
            path.addEllipse(in: CGRect(
                x: center.x - innerR, y: center.y - innerR,
                width: innerR * 2, height: innerR * 2
            ))
            return path
        }

        // Normal case: build a single continuous closed path
        //   outer arc (start → end, going clockwise visually)
        // → end cap semicircle (outer end → inner end)
        // → inner arc (end → start, going counter-clockwise visually)
        // → start cap semicircle (inner start → outer start)

        let outerStart = CGPoint(
            x: center.x + outerR * CGFloat(cos(startRad)),
            y: center.y + outerR * CGFloat(sin(startRad))
        )

        var path = Path()
        path.move(to: outerStart)

        // 1. Outer arc: startRad → endRad, clockwise in SwiftUI = false
        //    (in SwiftUI's flipped-Y coordinate system, clockwise:false draws
        //    in the direction of increasing angle, which is visually clockwise)
        path.addArc(
            center: center,
            radius: outerR,
            startAngle: Angle(radians: startRad),
            endAngle: Angle(radians: endRad),
            clockwise: false
        )

        // 2. End cap: semicircle centered on the base circle at endRad,
        //    going from outer (endRad) to inner (endRad + π) on the outer side
        let endCapCenter = CGPoint(
            x: center.x + baseRadius * CGFloat(cos(endRad)),
            y: center.y + baseRadius * CGFloat(sin(endRad))
        )
        path.addArc(
            center: endCapCenter,
            radius: capRadius,
            startAngle: Angle(radians: endRad),
            endAngle: Angle(radians: endRad + .pi),
            clockwise: false
        )

        // 3. Inner arc: endRad → startRad, going backward (clockwise: true)
        path.addArc(
            center: center,
            radius: innerR,
            startAngle: Angle(radians: endRad),
            endAngle: Angle(radians: startRad),
            clockwise: true
        )

        // 4. Start cap: semicircle centered on base at startRad,
        //    from inner (startRad + π) to outer (startRad)
        let startCapCenter = CGPoint(
            x: center.x + baseRadius * CGFloat(cos(startRad)),
            y: center.y + baseRadius * CGFloat(sin(startRad))
        )
        path.addArc(
            center: startCapCenter,
            radius: capRadius,
            startAngle: Angle(radians: startRad + .pi),
            endAngle: Angle(radians: startRad),
            clockwise: false
        )

        path.closeSubpath()
        return path
    }
}
