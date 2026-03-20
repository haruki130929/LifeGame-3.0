import SwiftUI

struct FabButton: View {
    @EnvironmentObject var fab: FabStore
    @EnvironmentObject private var theme: ThemeStore

    @State private var isRingActive = false
    @State private var highlightedIndex: Int?
    @State private var fabGlobalCenter: CGPoint = .zero
    @State private var ringRotation: CGFloat = 0
    @State private var scrollSpeed: CGFloat = 0
    @State private var scrollTimer: Timer?

    private let fabCircleSize: CGFloat = 60
    private let ringDeadZone: CGFloat = 30
    private let edgeScrollMargin: CGFloat = 0.2
    private let scrollRate: CGFloat = 0.03

    private var fabCircleBg: Color {
        theme.isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.08)
    }
    private var fabForeground: Color {
        theme.isDark ? .white.opacity(0.95) : Color(.label)
    }

    /// 將 FabStore 的資料轉成 RingItem
    /// 首頁：顯示 currentFeatures（卡片功能）
    /// 功能頁：顯示 actions（該功能的操作）
    private var ringItems: [RingItem] {
        if fab.currentFeatures.count > 1 {
            // 首頁模式：多個功能
            return fab.currentFeatures.map { feature in
                RingItem(id: feature.rawValue, icon: fab.icon(for: feature), title: fab.title(for: feature))
            }
        } else {
            // 功能頁模式：顯示該功能的操作
            return fab.actions.map { action in
                RingItem(id: action.id.uuidString, icon: action.systemImage, title: action.title)
            }
        }
    }

    var body: some View {
        Circle()
            .fill(fabCircleBg)
            .frame(width: fabCircleSize, height: fabCircleSize)
            .overlay(
                Image(systemName: "plus")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(fabForeground)
            )
            .overlay(Circle().stroke(
                theme.isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.08),
                lineWidth: 1))
            .shadow(color: .black.opacity(theme.isDark ? 0.25 : 0.12), radius: 12, x: 0, y: 8)
            .scaleEffect(isRingActive ? 0.85 : 1.0)
            .rotationEffect(.degrees(isRingActive ? 45 : 0))
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        let f = geo.frame(in: .global)
                        fabGlobalCenter = CGPoint(x: f.midX, y: f.midY)
                    }
                }
            )
            .overlay {
                if isRingActive {
                    FabRingView(
                        items: ringItems,
                        highlightedIndex: highlightedIndex,
                        rotationOffset: ringRotation,
                        isDark: theme.isDark
                    )
                    .allowsHitTesting(false)
                    .transition(.scale(scale: 0.4, anchor: .bottomTrailing).combined(with: .opacity))
                }
            }
            .gesture(
                LongPressGesture(minimumDuration: 0.3)
                    .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
                    .onChanged { value in
                        switch value {
                        case .first(true):
                            if !isRingActive { activateRing() }
                        case .second(true, let drag):
                            if !isRingActive { activateRing() }
                            if let drag { handleDrag(at: drag.location) }
                        default:
                            break
                        }
                    }
                    .onEnded { _ in
                        completeSelection()
                    }
            )
            .accessibilityLabel("選單")
    }

    // MARK: - Ring Activation

    private func activateRing() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
            isRingActive = true
        }
        ringRotation = 0
        scrollSpeed = 0
        stopScrollTimer()
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.impactOccurred()
    }

    // MARK: - Drag Handling

    private func handleDrag(at location: CGPoint) {
        let dx = location.x - fabGlobalCenter.x
        let dy = location.y - fabGlobalCenter.y
        let distance = sqrt(dx * dx + dy * dy)

        guard distance > ringDeadZone else {
            if highlightedIndex != nil {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    highlightedIndex = nil
                }
            }
            stopScrollTimer()
            return
        }

        let fingerAngle = atan2(dy, dx)
        updateHighlight(fingerAngle: fingerAngle)
        checkEdgeScroll(fingerAngle: fingerAngle)
    }

    private func updateHighlight(fingerAngle: CGFloat) {
        let items = ringItems
        guard !items.isEmpty else { return }

        var bestIndex: Int?
        var bestDist: CGFloat = .infinity

        for i in items.indices {
            let itemAngle = FabRingView.itemAngle(index: i, total: items.count, offset: ringRotation)
            let vis = FabRingView.visibility(angle: itemAngle)
            guard vis > 0.3 else { continue }

            let d = abs(FabRingView.normalizeAngle(fingerAngle - itemAngle))
            if d < bestDist {
                bestDist = d
                bestIndex = i
            }
        }

        if bestIndex != highlightedIndex {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                highlightedIndex = bestIndex
            }
            if bestIndex != nil {
                let g = UIImpactFeedbackGenerator(style: .light)
                g.impactOccurred()
            }
        }
    }

    // MARK: - 邊緣滾動

    private func checkEdgeScroll(fingerAngle: CGFloat) {
        let arcMid = (FabRingView.visibleStart + FabRingView.visibleEnd) / 2
        let halfArc = abs(FabRingView.visibleEnd - FabRingView.visibleStart) / 2

        let diff = FabRingView.normalizeAngle(fingerAngle - arcMid)

        guard abs(diff) <= halfArc + 0.3 else {
            stopScrollTimer()
            return
        }

        if diff < -(halfArc - edgeScrollMargin) {
            startScrollTimer(direction: 1)
        } else if diff > (halfArc - edgeScrollMargin) {
            startScrollTimer(direction: -1)
        } else {
            stopScrollTimer()
        }
    }

    private func startScrollTimer(direction: CGFloat) {
        let newSpeed = scrollRate * direction
        if scrollTimer != nil && scrollSpeed == newSpeed { return }

        stopScrollTimer()
        scrollSpeed = newSpeed

        scrollTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.linear(duration: 0.016)) {
                    ringRotation += scrollSpeed
                }
            }
        }
        if let timer = scrollTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopScrollTimer() {
        scrollTimer?.invalidate()
        scrollTimer = nil
        scrollSpeed = 0
    }

    // MARK: - Selection

    private func completeSelection() {
        stopScrollTimer()
        let idx = highlightedIndex

        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            isRingActive = false
            highlightedIndex = nil
        }
        ringRotation = 0

        guard let idx else { return }

        let g = UIImpactFeedbackGenerator(style: .medium)
        g.impactOccurred()

        if fab.currentFeatures.count > 1 {
            // 首頁：導航到功能頁
            guard idx < fab.currentFeatures.count else { return }
            fab.route = .navigate(fab.currentFeatures[idx])
        } else {
            // 功能頁：執行對應的 action
            guard idx < fab.actions.count else { return }
            fab.actions[idx].action()
        }
    }
}
