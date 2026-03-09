import SwiftUI

struct RingSelectionMarkers: View {
    let startMinute: Int
    let endMinute: Int
    let color: Color
    
    /// 這個半徑比例要跟 RingTimeTicks 的 tickRadiusRatio 對齊
    let markerRadiusRatio: CGFloat
    
    /// 線段長度（越大越明顯）
    let markerLen: CGFloat
    
    /// 線段粗細
    let lineWidth: CGFloat
    
    /// 可加一點白色描邊做質感（可留 0）
    let strokeOpacity: CGFloat
    
    private let totalMinutes = 1440
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let r = size * markerRadiusRatio / 2
            
            ZStack {
                // 可選：先畫一層淡白線當描邊（更清楚）
                if strokeOpacity > 0 {
                    markerLine(minute: startMinute, center: center, radius: r)
                        .stroke(.white.opacity(strokeOpacity), style: StrokeStyle(lineWidth: lineWidth + 1, lineCap: .round))
                    
                    markerLine(minute: endMinute, center: center, radius: r)
                        .stroke(.white.opacity(strokeOpacity), style: StrokeStyle(lineWidth: lineWidth + 1, lineCap: .round))
                }
                
                // 主線（用時段顏色）
                markerLine(minute: startMinute, center: center, radius: r)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                
                markerLine(minute: endMinute, center: center, radius: r)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
        .allowsHitTesting(false)
    }
    
    // 兩點之間的放射短線（沿著該 minute 的角度）
    private func markerLine(minute: Int, center: CGPoint, radius: CGFloat) -> Path {
        let ang = angleForMinute(minute)
        let dx = cos(ang)
        let dy = sin(ang)
        
        // 讓線段「貼著刻度圈」：以 radius 為外端，往內縮 markerLen
        let pOuter = CGPoint(x: center.x + dx * radius, y: center.y + dy * radius)
        let pInner = CGPoint(x: center.x + dx * (radius - markerLen), y: center.y + dy * (radius - markerLen))
        
        var path = Path()
        path.move(to: pInner)
        path.addLine(to: pOuter)
        return path
    }
    
    // 12 點方向為 0，順時針
    private func angleForMinute(_ minute: Int) -> CGFloat {
        let m = (minute % totalMinutes + totalMinutes) % totalMinutes
        let frac = CGFloat(m) / CGFloat(totalMinutes)
        return (frac * 2 * .pi) - (.pi / 2)
    }
}
