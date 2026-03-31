import SwiftUI

/// 一個填充型的厚圓弧，兩端自帶半圓收尾，不會超出角度範圍
struct ThickArcShape: Shape {
    let startMinute: Int
    let endMinute: Int
    let totalMinutes: Int
    let thickness: CGFloat   // 圓弧的粗細（等同於之前的 lineWidth）

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseR = Double(min(rect.width, rect.height) / 2)
        let half = Double(thickness / 2)
        let outerR = baseR + half
        let innerR = max(baseR - half, 0)

        func angle(_ minute: Int) -> Double {
            let f = Double((minute % totalMinutes + totalMinutes) % totalMinutes) / Double(totalMinutes)
            return f * 2 * .pi - .pi / 2
        }

        let a0 = angle(startMinute)
        let a1 = angle(endMinute)

        // 端點的圓心（在 baseR 上）
        let startCenter = CGPoint(
            x: center.x + cos(a0) * baseR,
            y: center.y + sin(a0) * baseR
        )
        let endCenter = CGPoint(
            x: center.x + cos(a1) * baseR,
            y: center.y + sin(a1) * baseR
        )

        var p = Path()

        // 1. 起點半圓 cap（從內到外，逆時針半圓）
        p.addArc(
            center: startCenter,
            radius: half,
            startAngle: .radians(a0 + .pi),  // 指向圓心方向
            endAngle: .radians(a0),            // 指向外側
            clockwise: false
        )

        // 2. 外弧（順時針方向，從 start 到 end）
        if endMinute >= startMinute {
            p.addArc(center: center, radius: outerR,
                     startAngle: .radians(a0), endAngle: .radians(a1), clockwise: false)
        } else {
            // 跨午夜
            p.addArc(center: center, radius: outerR,
                     startAngle: .radians(a0), endAngle: .radians(.pi * 1.5), clockwise: false)
            p.addArc(center: center, radius: outerR,
                     startAngle: .radians(-.pi / 2), endAngle: .radians(a1), clockwise: false)
        }

        // 3. 終點半圓 cap（從外到內）
        p.addArc(
            center: endCenter,
            radius: half,
            startAngle: .radians(a1),
            endAngle: .radians(a1 + .pi),
            clockwise: false
        )

        // 4. 內弧（逆時針方向，從 end 回到 start）
        if endMinute >= startMinute {
            p.addArc(center: center, radius: innerR,
                     startAngle: .radians(a1), endAngle: .radians(a0), clockwise: true)
        } else {
            p.addArc(center: center, radius: innerR,
                     startAngle: .radians(a1), endAngle: .radians(-.pi / 2), clockwise: true)
            p.addArc(center: center, radius: innerR,
                     startAngle: .radians(.pi * 1.5), endAngle: .radians(a0), clockwise: true)
        }

        p.closeSubpath()
        return p
    }
}
