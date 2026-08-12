import SwiftUI

// MARK: - 能力值模型

struct AbilitySet: Codable, Equatable {
    var stamina: Int       // 體力
    var focus: Int          // 專注力
    var execution: Int      // 執行力
    var awareness: Int      // 覺察力
    var timeManagement: Int // 時間管理

    static let `default` = AbilitySet(
        stamina: 5, focus: 5, execution: 5, awareness: 5, timeManagement: 5
    )

    var values: [Int] { [stamina, focus, execution, awareness, timeManagement] }

    static var labels: [String] {
        [String(localized: "體力"), String(localized: "專注力"), String(localized: "執行力"), String(localized: "覺察力"), String(localized: "時間管理")]
    }
    static let icons = ["figure.run", "eye", "bolt.fill", "brain.head.profile", "clock"]
    static let maxValue = 10
}

// MARK: - 五角圖

struct AbilityPentagonView: View {
    let abilities: AbilitySet
    let isDark: Bool

    private let sides = 5
    private let gridLevels = 5   // 背景同心五角形層數

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 * 0.7

            ZStack {
                // 背景網格
                ForEach(1...gridLevels, id: \.self) { level in
                    let scale = CGFloat(level) / CGFloat(gridLevels)
                    PentagonShape(sides: sides, scale: scale)
                        .stroke(
                            isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06),
                            lineWidth: 1
                        )
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)
                }

                // 軸線
                ForEach(0..<sides, id: \.self) { i in
                    let angle = angleFor(index: i)
                    let endX = center.x + cos(angle) * radius
                    let endY = center.y + sin(angle) * radius

                    Path { path in
                        path.move(to: center)
                        path.addLine(to: CGPoint(x: endX, y: endY))
                    }
                    .stroke(
                        isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04),
                        lineWidth: 1
                    )
                }

                // 數值填充區域
                AbilityFillShape(
                    sides: sides,
                    values: abilities.values.map { CGFloat($0) / CGFloat(AbilitySet.maxValue) }
                )
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.35), Color.cyan.opacity(0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: radius * 2, height: radius * 2)
                .position(center)

                // 數值邊框
                AbilityFillShape(
                    sides: sides,
                    values: abilities.values.map { CGFloat($0) / CGFloat(AbilitySet.maxValue) }
                )
                .stroke(Color.cyan.opacity(0.8), lineWidth: 2)
                .frame(width: radius * 2, height: radius * 2)
                .position(center)

                // 頂點圓點
                ForEach(0..<sides, id: \.self) { i in
                    let value = CGFloat(abilities.values[i]) / CGFloat(AbilitySet.maxValue)
                    let angle = angleFor(index: i)
                    let x = center.x + cos(angle) * radius * value
                    let y = center.y + sin(angle) * radius * value

                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 8, height: 8)
                        .shadow(color: .cyan.opacity(0.5), radius: 4)
                        .position(x: x, y: y)
                }

                // 標籤
                ForEach(0..<sides, id: \.self) { i in
                    let angle = angleFor(index: i)
                    let labelRadius = radius * 1.22
                    let x = center.x + cos(angle) * labelRadius
                    let y = center.y + sin(angle) * labelRadius

                    VStack(spacing: 2) {
                        Image(systemName: AbilitySet.icons[i])
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text(AbilitySet.labels[i])
                            .font(.caption2.bold())
                            .foregroundStyle(isDark ? .white.opacity(0.8) : Color(.label))
                        Text("\(abilities.values[i])")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .position(x: x, y: y)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// 從正上方開始，順時針排列
    private func angleFor(index: Int) -> CGFloat {
        let start: CGFloat = -.pi / 2  // 正上方
        return start + (2 * .pi / CGFloat(sides)) * CGFloat(index)
    }
}

// MARK: - 五角形 Shape（背景網格用）

private struct PentagonShape: Shape {
    let sides: Int
    let scale: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * scale
        var path = Path()

        for i in 0..<sides {
            let angle = -.pi / 2 + (2 * .pi / CGFloat(sides)) * CGFloat(i)
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
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

// MARK: - 數值填充 Shape

private struct AbilityFillShape: Shape {
    let sides: Int
    let values: [CGFloat]  // 0.0 ~ 1.0

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()

        for i in 0..<sides {
            let angle = -.pi / 2 + (2 * .pi / CGFloat(sides)) * CGFloat(i)
            let value = i < values.count ? values[i] : 0
            let point = CGPoint(
                x: center.x + cos(angle) * radius * value,
                y: center.y + sin(angle) * radius * value
            )
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
