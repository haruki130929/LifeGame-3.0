import SwiftUI

struct RingHourLabels: View {
    let totalMinutes: Int = 1440
    
    /// 文字貼近內圈的比例（1 = 外圈，越小越往內）
    let labelRadiusRatio: CGFloat
    
    /// 字的大小
    let font: Font
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            
            ZStack {
                ForEach(0..<24, id: \.self) { hour in
                    let minute = hour * 60
                    let angle = angleForMinute(minute)          // radians
                    let r = size * labelRadiusRatio / 2
                    let p = point(center: center, radius: r, angle: angle)
                    
                    Text(String(format: "%02d", hour))
                        .font(font)
                        .foregroundStyle(.white.opacity(0.35))
                        .monospacedDigit()
                        .position(p)
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    // 12 點方向為 0，順時針
    private func angleForMinute(_ minute: Int) -> CGFloat {
        let frac = CGFloat(minute) / CGFloat(totalMinutes)
        return frac * 2 * .pi - (.pi / 2)
    }
    
    private func point(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }
}
