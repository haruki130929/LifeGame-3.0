import SwiftUI

struct TargetView: View {
    @Binding var shots: [ShotPoint]
    let hitRadius: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                GeometryReader { geo in
                    let size = min(geo.size.width, geo.size.height)
                    
                    ZStack {
                        // 靶（同心圓）
                        TargetRings()
                            .frame(width: size, height: size)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        
                        // 中靶半徑圈（判定用，讓使用者知道「哪裡算中」）
                        Circle()
                            .stroke(.green.opacity(0.35), lineWidth: 2)
                            .frame(width: size * hitRadius * 2, height: size * hitRadius * 2)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        
                        // 落點
                        ForEach(shots) { s in
                            let px = geo.size.width * s.x
                            let py = geo.size.height * s.y
                            Circle()
                                .fill(KyudoMath.isHit(s, hitRadius: hitRadius) ? .red : .blue)
                                .frame(width: 10, height: 10)
                                .position(x: px, y: py)
                                .shadow(radius: 1)
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let x = max(0, min(1, value.location.x / geo.size.width))
                                let y = max(0, min(1, value.location.y / geo.size.height))
                                shots.append(ShotPoint(x: x, y: y))
                            }
                    )
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            HStack {
                let hits = KyudoMath.hitCount(shots: shots, hitRadius: hitRadius)
                let total = shots.count
                let rate = KyudoMath.hitRatePercent(shots: shots, hitRadius: hitRadius)
                
                Text("中靶：\(hits)/\(total)（\(rate)%）")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(role: .destructive) {
                    shots.removeAll()
                } label: {
                    Label("清除落點", systemImage: "trash")
                        .font(.subheadline)
                }
            }
        }
    }
}

private struct TargetRings: View {
    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radii: [CGFloat] = [0.48, 0.36, 0.24, 0.12].map { $0 * min(size.width, size.height) }
            
            // 背景
            let bg = Path(ellipseIn: CGRect(x: center.x - radii[0], y: center.y - radii[0],
                                            width: radii[0] * 2, height: radii[0] * 2))
            ctx.fill(bg, with: .color(.black.opacity(0.03)))
            
            for (i, r) in radii.enumerated() {
                let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                let ring = Path(ellipseIn: rect)
                ctx.stroke(ring, with: .color(.gray.opacity(i == radii.count - 1 ? 0.8 : 0.45)), lineWidth: 2)
            }
            
            // 十字準星
            var cross = Path()
            cross.move(to: CGPoint(x: center.x, y: center.y - radii[0]))
            cross.addLine(to: CGPoint(x: center.x, y: center.y + radii[0]))
            cross.move(to: CGPoint(x: center.x - radii[0], y: center.y))
            cross.addLine(to: CGPoint(x: center.x + radii[0], y: center.y))
            ctx.stroke(cross, with: .color(.gray.opacity(0.25)), lineWidth: 1)
        }
    }
}
