import SwiftUI

/// 雷達圖（Spider Chart）— Swift Charts 不支援，使用 Path 手繪
struct RadarChartView: View {
    let axes: [String]
    let values: [Double]  // 0...1 歸一化值，每個軸一個
    var gridLevels: Int = 5
    var fillColor: Color = .blue

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size * 0.38
            let labelRadius = size * 0.48
            let count = axes.count

            ZStack {
                // 網格
                ForEach(1...gridLevels, id: \.self) { level in
                    let scale = Double(level) / Double(gridLevels)
                    polygonPath(center: center, radius: radius * scale, sides: count)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                }

                // 軸線
                ForEach(0..<count, id: \.self) { i in
                    let angle = angleFor(index: i, total: count)
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: pointOnCircle(center: center, radius: radius, angle: angle))
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                }

                // 資料多邊形
                if values.count == count, count >= 3 {
                    dataPath(center: center, radius: radius, count: count)
                        .fill(fillColor.opacity(0.2))

                    dataPath(center: center, radius: radius, count: count)
                        .stroke(fillColor, lineWidth: 2)

                    // 資料點
                    ForEach(0..<count, id: \.self) { i in
                        let angle = angleFor(index: i, total: count)
                        let r = radius * max(0, min(1, values[i]))
                        let point = pointOnCircle(center: center, radius: r, angle: angle)
                        Circle()
                            .fill(fillColor)
                            .frame(width: 6, height: 6)
                            .position(point)
                    }
                }

                // 軸標籤
                ForEach(0..<count, id: \.self) { i in
                    let angle = angleFor(index: i, total: count)
                    let point = pointOnCircle(center: center, radius: labelRadius, angle: angle)
                    Text(axes[i])
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .position(point)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Geometry

    private func angleFor(index: Int, total: Int) -> Double {
        // 從正上方開始，順時針
        let base = -Double.pi / 2
        return base + (2 * .pi / Double(total)) * Double(index)
    }

    private func pointOnCircle(center: CGPoint, radius: Double, angle: Double) -> CGPoint {
        CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }

    private func polygonPath(center: CGPoint, radius: Double, sides: Int) -> Path {
        guard sides >= 3 else { return Path() }
        var path = Path()
        for i in 0..<sides {
            let angle = angleFor(index: i, total: sides)
            let point = pointOnCircle(center: center, radius: radius, angle: angle)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    private func dataPath(center: CGPoint, radius: Double, count: Int) -> Path {
        var path = Path()
        for i in 0..<count {
            let angle = angleFor(index: i, total: count)
            let r = radius * max(0, min(1, values[i]))
            let point = pointOnCircle(center: center, radius: r, angle: angle)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
