import SwiftUI

struct DayRingView: View {
    let blocks: [ScheduleBlock]
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
            let outerR = size * 0.48
            let innerR = size * 0.28
            
            ZStack {
                // 底圈（24 小時刻度）
                Circle()
                    .stroke(.secondary.opacity(0.25), lineWidth: 2)
                
                // 扇形區塊
                ForEach(blocks) { b in
                    SectorRingShape(startHour: b.startHour, endHour: b.endHour, innerRadiusRatio: innerR/outerR)
                        .fill(colorForTitle(b.title).opacity(0.85))
                }
                
                // 中間空心
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: innerR*2, height: innerR*2)
                    .overlay(
                        VStack(spacing: 6) {
                            Text("行程")
                                .font(.headline)
                            Text("24 小時")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    )
                
                // 12/3/6/9 提示
                Text("0")
                    .font(.caption)
                    .position(x: center.x, y: center.y - outerR - 10)
                Text("6")
                    .font(.caption)
                    .position(x: center.x + outerR + 10, y: center.y)
                Text("12")
                    .font(.caption)
                    .position(x: center.x, y: center.y + outerR + 10)
                Text("18")
                    .font(.caption)
                    .position(x: center.x - outerR - 14, y: center.y)
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width/2, y: geo.size.height/2)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
    }
    
    /// 先用「文字 hash」給固定顏色，之後想改成挑色也可以
    private func colorForTitle(_ title: String) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal, .indigo, .mint]
        let v = abs(title.hashValue)
        return colors[v % colors.count]
    }
}

struct SectorRingShape: Shape {
    let startHour: Int
    let endHour: Int
    let innerRadiusRatio: CGFloat   // 0~1
    
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let rOuter = min(rect.width, rect.height) / 2
        let rInner = rOuter * innerRadiusRatio
        
        // 0 小時在正上方：-90 度
        func angle(forHour h: Int) -> Angle {
            let deg = -90 + (Double(h) / 24.0) * 360.0
            return .degrees(deg)
        }
        
        let a0 = angle(forHour: startHour)
        let a1 = angle(forHour: endHour)
        
        var p = Path()
        p.addArc(center: c, radius: rOuter, startAngle: a0, endAngle: a1, clockwise: false)
        p.addArc(center: c, radius: rInner, startAngle: a1, endAngle: a0, clockwise: true)
        p.closeSubpath()
        return p
    }
}
