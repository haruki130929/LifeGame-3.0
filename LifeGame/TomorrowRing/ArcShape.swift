import SwiftUI

struct ArcShape: Shape {
    let startMinute: Int
    let endMinute: Int
    let totalMinutes: Int
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        
        func angle(_ minute: Int) -> Angle {
            // 12點方向為 0，順時針
            let f = Double((minute % totalMinutes + totalMinutes) % totalMinutes) / Double(totalMinutes)
            return .degrees(f * 360 - 90)
        }
        
        let a0 = angle(startMinute)
        let a1 = angle(endMinute)
        
        var p = Path()
        
        // 支援跨午夜：end < start 就切成兩段畫
        if endMinute >= startMinute {
            p.addArc(center: center, radius: r, startAngle: a0, endAngle: a1, clockwise: false)
        } else {
            p.addArc(center: center, radius: r, startAngle: a0, endAngle: .degrees(270), clockwise: false) // 到 24:00
            p.addArc(center: center, radius: r, startAngle: .degrees(-90), endAngle: a1, clockwise: false) // 從 00:00
        }
        
        return p
    }
}
