import SwiftUI

struct RingTimeTicks: View {
    let totalMinutes: Int = 1440
    
    /// 每幾分鐘一條刻度（你要 5）
    let tickEvery: Int
    
    /// 整點刻度加長（60）
    let majorTickEvery: Int
    
    /// 刻度要貼哪個半徑（用比例，會跟著 size 變）
    /// 1.0 = 外圓邊界；0.5 = 中間；建議 0.62~0.68 貼內圈
    let tickRadiusRatio: CGFloat
    
    /// 小刻度長度
    let minorTickLen: CGFloat
    
    /// 大刻度長度
    let majorTickLen: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let rOuter = size * tickRadiusRatio / 2
            
            Canvas { ctx, _ in
                for minute in stride(from: 0, to: totalMinutes, by: tickEvery) {
                    let isMajor = (minute % majorTickEvery == 0)
                    let len = isMajor ? majorTickLen : minorTickLen
                    let w: CGFloat = isMajor ? 3 : 2.2
                    
                    let angle = angleForMinute(minute)
                    let p1 = point(center: center, radius: rOuter, angle: angle)
                    let p2 = point(center: center, radius: rOuter - len, angle: angle)
                    
                    var path = Path()
                    path.move(to: p1)
                    path.addLine(to: p2)
                    
                    ctx.stroke(path,
                               with: .color(.white.opacity(isMajor ? 0.40 : 0.22)),
                               lineWidth: w)
                }
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
