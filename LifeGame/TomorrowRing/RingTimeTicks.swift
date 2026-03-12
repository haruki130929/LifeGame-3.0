import SwiftUI

struct RingTimeTicks: View {
    let totalMinutes: Int = 1440

    /// 每幾分鐘一條刻度
    let tickEvery: Int

    /// 整點刻度加長（60）
    let majorTickEvery: Int

    /// 圓環線寬，用來算刻度最外點 = size/2 + ringLineWidth/2
    let ringLineWidth: CGFloat

    /// 小刻度長度
    let minorTickLen: CGFloat

    /// 大刻度長度
    let majorTickLen: CGFloat

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let rOuter = size / 2 + ringLineWidth / 2

            let iPad = Layout.isIPad

            // ✅ 用 Path 而非 Canvas，避免邊界裁切
            ZStack {
                // 小刻度
                Path { path in
                    for minute in stride(from: 0, to: totalMinutes, by: tickEvery) {
                        guard minute % majorTickEvery != 0 else { continue }
                        let angle = angleForMinute(minute)
                        path.move(to: point(center: center, radius: rOuter, angle: angle))
                        path.addLine(to: point(center: center, radius: rOuter - minorTickLen, angle: angle))
                    }
                }
                .stroke(
                    .primary.opacity(iPad ? 0.40 : 0.28),
                    lineWidth: iPad ? 2.8 : 2.2
                )

                // 大刻度（整點）
                Path { path in
                    for minute in stride(from: 0, to: totalMinutes, by: majorTickEvery) {
                        let angle = angleForMinute(minute)
                        path.move(to: point(center: center, radius: rOuter, angle: angle))
                        path.addLine(to: point(center: center, radius: rOuter - majorTickLen, angle: angle))
                    }
                }
                .stroke(
                    .primary.opacity(iPad ? 0.60 : 0.48),
                    lineWidth: iPad ? 3.5 : 3
                )
            }
        }
    }

    // 12 點方向為 0，順時針增加
    private func angleForMinute(_ minute: Int) -> CGFloat {
        let frac = CGFloat(minute) / CGFloat(totalMinutes)
        return frac * 2 * .pi - .pi / 2
    }

    private func point(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius)
    }
}
