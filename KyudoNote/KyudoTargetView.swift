import SwiftUI

struct KyudoTargetView: View {
    let hits: [KyudoHit]
    let onTapAddHit: (_ normalizedX: CGFloat, _ normalizedY: CGFloat) -> Void
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size * 0.45
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.06))
                
                TargetRings(center: center, radius: radius)
                
                ForEach(hits) { hit in
                    let p = CGPoint(
                        x: center.x + hit.x * radius,
                        y: center.y + hit.y * radius
                    )
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .position(p)
                        .shadow(radius: 1)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let nx = (value.location.x - center.x) / radius
                        let ny = (value.location.y - center.y) / radius
                        onTapAddHit(nx, ny)
                    }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct TargetRings: View {
    let center: CGPoint
    let radius: CGFloat
    
    var body: some View {
        ZStack {
            ring(scale: 1.0)
            ring(scale: 0.8)
            ring(scale: 0.6)
            ring(scale: 0.4)
            ring(scale: 0.2)
            
            Circle()
                .fill(Color.black)
                .frame(width: radius * 0.06, height: radius * 0.06)
                .position(center)
        }
    }
    
    private func ring(scale: CGFloat) -> some View {
        Circle()
            .stroke(Color.black, lineWidth: 3)
            .frame(width: radius * 2 * scale, height: radius * 2 * scale)
            .position(center)
    }
}
