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
    let highlightedVirtualIndex: Int?
    let rotationOffset: CGFloat
    let isDark: Bool

    /// 圓環半徑
    static let ringRadius: CGFloat = 120
    private let iconSize: CGFloat = 46

    /// 弧形範圍：FAB 在右下角，圓環往左上展開
    /// 從 180°（正左方）到 270°（正上方），即第三象限的四分之一圈
    /// 用弧度：π 到 1.5π（但用負角表示：-π 到 -0.5π）
    static let arcStart: CGFloat = -.pi * 0.5   // 正上方（12 點鐘）
    static let arcEnd: CGFloat   = -.pi          // 正左方（9 點鐘）

    /// 弧形角度範圍
    static let arcSpan: CGFloat = abs(arcEnd - arcStart)  // 0.5π ≈ 90°

    /// 項目間距（固定）
    static let itemSpacing: CGFloat = .pi * 0.14  // ≈ 25°

    var body: some View {
        ZStack {
            // 弧形軌道背景
            ArcTrack(startAngle: Self.arcStart, endAngle: Self.arcEnd, radius: Self.ringRadius)
                .stroke(
                    isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04),
                    style: StrokeStyle(lineWidth: 48, lineCap: .round)
                )

            // 功能圖示
            ForEach(computeVisibleItems(), id: \.virtualIndex) { vi in
                ringItemView(vi: vi)
            }
        }
    }

    // MARK: - 可見項目計算

    struct VisibleItem {
        let virtualIndex: Int
        let realIndex: Int
        let angle: CGFloat
        let visibility: CGFloat
    }

    private func computeVisibleItems() -> [VisibleItem] {
        let count = items.count
        guard count > 0 else { return [] }

        let arcMid = (Self.arcStart + Self.arcEnd) / 2
        let estimatedCenter = Int((Self.arcStart - arcMid + rotationOffset) / Self.itemSpacing)

        var candidates: [VisibleItem] = []
        for vi in (estimatedCenter - 10)...(estimatedCenter + 10) {
            let angle = Self.angleFor(virtualIndex: vi, offset: rotationOffset)
            let vis = Self.itemVisibility(angle: angle)
            if vis > 0.1 {
                let realIndex = ((vi % count) + count) % count
                candidates.append(VisibleItem(
                    virtualIndex: vi, realIndex: realIndex,
                    angle: angle, visibility: vis
                ))
            }
        }

        // 去重：同一個 realIndex 只保留可見度最高的
        var best: [Int: VisibleItem] = [:]
        for item in candidates {
            if let existing = best[item.realIndex] {
                if item.visibility > existing.visibility {
                    best[item.realIndex] = item
                }
            } else {
                best[item.realIndex] = item
            }
        }

        return Array(best.values).sorted { $0.virtualIndex < $1.virtualIndex }
    }

    // MARK: - 單一項目 View

    private func ringItemView(vi: VisibleItem) -> some View {
        let isHighlighted = highlightedVirtualIndex == vi.virtualIndex
        let item = items[vi.realIndex]
        let x = cos(vi.angle) * Self.ringRadius
        let y = sin(vi.angle) * Self.ringRadius

        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(bgColor(highlighted: isHighlighted))
                    .frame(width: iconSize, height: iconSize)

                Image(systemName: item.icon)
                    .font(.system(size: isHighlighted ? 22 : 17, weight: .semibold))
                    .foregroundStyle(fgColor(highlighted: isHighlighted))
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
            .shadow(color: isHighlighted ? .black.opacity(0.25) : .clear, radius: 10, x: 0, y: 4)

            if isHighlighted {
                Text(item.title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isDark ? .white : Color(.label))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(isDark ? Color.white.opacity(0.18) : Color.black.opacity(0.08)))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .scaleEffect(isHighlighted ? 1.2 : 1.0)
        .opacity(vi.visibility)
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isHighlighted)
        .offset(x: x, y: y)
    }

    // MARK: - 角度計算

    /// virtualIndex 0 = arcStart（最右邊/最上面），往 arcEnd（左邊）遞增
    static func angleFor(virtualIndex: Int, offset: CGFloat) -> CGFloat {
        return arcStart - itemSpacing * CGFloat(virtualIndex) + offset
    }

    /// 正規化角度到 [-π, π]
    static func normalizeAngle(_ a: CGFloat) -> CGFloat {
        var r = a
        while r > .pi { r -= 2 * .pi }
        while r < -.pi { r += 2 * .pi }
        return r
    }

    /// 項目可見度（在弧形內=1，邊緣淡出，外=0）
    static func itemVisibility(angle: CGFloat) -> CGFloat {
        let mid = (arcStart + arcEnd) / 2   // 弧形中心
        let halfArc = arcSpan / 2            // 弧形半寬
        let fadeMargin: CGFloat = 0.15       // 邊緣淡出範圍

        let diff = abs(normalizeAngle(angle - mid))

        if diff <= halfArc - fadeMargin {
            return 1.0
        } else if diff <= halfArc + fadeMargin {
            return CGFloat(1.0 - (diff - (halfArc - fadeMargin)) / (2 * fadeMargin))
        }
        return 0.0
    }

    // MARK: - 顏色

    private func fgColor(highlighted: Bool) -> Color {
        highlighted
            ? (isDark ? .white : Color(.label))
            : (isDark ? .white.opacity(0.65) : Color(.label).opacity(0.55))
    }

    private func bgColor(highlighted: Bool) -> Color {
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
