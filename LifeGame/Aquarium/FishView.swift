import SwiftUI

/// 線稿魚：身體實心色塊 + 白色線條的尾鰭與眼睛。
/// 以 60×40 的設計座標繪製，再縮放到實際 frame；魚預設朝右，facingLeft 時水平翻轉。
struct FishView: View {
    let type: FishType
    let color: Color
    let facingLeft: Bool

    var body: some View {
        Canvas { context, size in
            let sx = size.width / 60.0
            let sy = size.height / 40.0
            func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * sx, y: y * sy) }

            // 尾鰭（白色線條勾勒）
            var tail = Path()
            tail.move(to: P(21, 20))
            tail.addLine(to: P(3, 8))
            tail.addLine(to: P(3, 32))
            tail.closeSubpath()
            context.stroke(tail, with: .color(.white),
                           style: StrokeStyle(lineWidth: 2.5 * sx, lineJoin: .round))

            // 身體（實心色塊）
            let body: Path
            switch type {
            case .social:
                body = Path(ellipseIn: CGRect(x: 19 * sx, y: 5 * sy, width: 30 * sx, height: 30 * sy))
            case .physical:
                body = Path(roundedRect: CGRect(x: 19 * sx, y: 5 * sy, width: 30 * sx, height: 30 * sy),
                            cornerRadius: 6 * sx)
            case .mental:
                var t = Path()
                t.move(to: P(19, 4))
                t.addLine(to: P(19, 36))
                t.addLine(to: P(51, 20))
                t.closeSubpath()
                body = t
            }
            context.fill(body, with: .color(color))

            // 眼睛（白色線圈 + 白點）
            let eye: (x: CGFloat, y: CGFloat)
            switch type {
            case .social:   eye = (42, 15)
            case .physical: eye = (42, 14)
            case .mental:   eye = (32, 16)
            }
            let r = 3.4 * sx
            let eyeRect = CGRect(x: eye.x * sx - r, y: eye.y * sy - r, width: r * 2, height: r * 2)
            context.stroke(Path(ellipseIn: eyeRect), with: .color(.white), lineWidth: 1.8 * sx)
            let dr = 1.1 * sx
            let dotRect = CGRect(x: (eye.x + 0.5) * sx - dr, y: eye.y * sy - dr, width: dr * 2, height: dr * 2)
            context.fill(Path(ellipseIn: dotRect), with: .color(.white))
        }
        .scaleEffect(x: facingLeft ? -1 : 1, y: 1)
    }
}
