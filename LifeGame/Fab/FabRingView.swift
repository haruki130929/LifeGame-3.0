import SwiftUI

// MARK: - 圓環項目模型

struct FabRingItem: Identifiable {
    let id: String
    let icon: String
    let title: String
}

// MARK: - FabRingView

struct FabRingView: View {
    let items: [FabRingItem]
    let highlightedIndex: Int?
    let rotationOffset: CGFloat
    let isDark: Bool

    private let ringRadius: CGFloat = 100
    private let iconSize: CGFloat = 46

    /// 可見弧形的固定範圍（FAB 在右下角，往左上展開）
    static let visibleStart: CGFloat = -.pi * 0.45
    static let visibleEnd: CGFloat   = -.pi * 1.15

    var body: some View {
        ZStack {
            // 弧形軌道背景
            ArcTrack(
                startAngle: Self.visibleStart,
                endAngle: Self.visibleEnd,
                radius: ringRadius
            )
            .stroke(
                isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04),
                style: StrokeStyle(lineWidth: 48, lineCap: .round)
            )

            // 功能圖示
            ForEach(items.indices, id: \.self) { index in
                let angle = Self.itemAngle(index: index, total: items.count, offset: rotationOffset)
                let vis = Self.visibility(angle: angle)

                if vis > 0.05 {
                    ringItem(index: index, item: items[index], angle: angle, visibility: vis)
                }
            }
        }
    }

    private func ringItem(index: Int, item: FabRingItem, angle: CGFloat, visibility: CGFloat) -> some View {
        let isHighlighted = highlightedIndex == index
        let x = cos(angle) * ringRadius
        let y = sin(angle) * ringRadius

        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(backgroundCircle(highlighted: isHighlighted))
                    .frame(width: iconSize, height: iconSize)

                Image(systemName: item.icon)
                    .font(.system(size: isHighlighted ? 22 : 17, weight: .semibold))
                    .foregroundStyle(foregroundColor(highlighted: isHighlighted))
            }
            .overlay(
                Circle().stroke(
                    isHighlighted
                        ? (isDark ? Color.white.opacity(0.5) : Color.black.opacity(0.25))
                        : Color.clear,
                    lineWidth: 1.5
                )
                .frame(width: iconSize, height: iconSize)
            )
            .shadow(
                color: isHighlighted ? .black.opacity(0.25) : .clear,
                radius: 10, x: 0, y: 4
            )

            if isHighlighted {
                Text(item.title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isDark ? .white : Color(.label))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(
                            isDark ? Color.white.opacity(0.18) : Color.black.opacity(0.08)
                        )
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .scaleEffect(isHighlighted ? 1.2 : 1.0)
        .opacity(visibility)
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isHighlighted)
        .offset(x: x, y: y)
    }

    // MARK: - 角度計算（循環排列）

    /// 固定間距，功能少時不會太分散
    private static let itemSpacing: CGFloat = .pi * 0.19  // ~34°

    static func itemAngle(index: Int, total: Int, offset: CGFloat) -> CGFloat {
        guard total > 0 else { return 0 }
        let arcCenter = (visibleStart + visibleEnd) / 2
        let totalSpan = itemSpacing * CGFloat(total - 1)
        let startAngle = arcCenter - totalSpan / 2
        return startAngle + itemSpacing * CGFloat(index) + offset
    }

    static func normalizeAngle(_ a: CGFloat) -> CGFloat {
        var r = a
        while r > .pi { r -= 2 * .pi }
        while r < -.pi { r += 2 * .pi }
        return r
    }

    static func visibility(angle: CGFloat) -> CGFloat {
        let mid = (visibleStart + visibleEnd) / 2
        let halfArc = abs(visibleEnd - visibleStart) / 2
        let fadeMargin: CGFloat = 0.2

        let diff = abs(normalizeAngle(angle - mid))

        if diff <= halfArc - fadeMargin {
            return 1.0
        } else if diff <= halfArc + fadeMargin {
            return CGFloat(1.0 - (diff - (halfArc - fadeMargin)) / (2 * fadeMargin))
        }
        return 0.0
    }

    private func foregroundColor(highlighted: Bool) -> Color {
        highlighted
            ? (isDark ? .white : Color(.label))
            : (isDark ? .white.opacity(0.65) : Color(.label).opacity(0.55))
    }

    private func backgroundCircle(highlighted: Bool) -> Color {
        highlighted
            ? (isDark ? Color.white.opacity(0.25) : Color.black.opacity(0.14))
            : (isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.07))
    }
}

// MARK: - Arc Track Shape

private struct ArcTrack: Shape {
    let startAngle: CGFloat
    let endAngle: CGFloat
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        Path { p in
            p.addArc(
                center: CGPoint(x: rect.midX, y: rect.midY),
                radius: radius,
                startAngle: .radians(startAngle),
                endAngle: .radians(endAngle),
                clockwise: true
            )
        }
    }
}
