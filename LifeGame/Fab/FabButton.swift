import SwiftUI

struct FabButton: View {
    @EnvironmentObject private var fab: FabStore

    var body: some View {
        if AppLayout.isIPad {
            FabButtoniPad()
        } else if FabStyle.current == .menu {
            FabButtoniPad()  // 選單模式
        } else {
            FabButtoniPhone() // 圓環模式
        }
    }
}

// MARK: - iPhone 版（長按手勢圓環）

private struct FabButtoniPhone: View {
    @EnvironmentObject var fab: FabStore
    @EnvironmentObject private var theme: ThemeStore

    @State private var isRingActive = false
    @State private var highlightedVI: Int?    // 虛擬索引（用於角度計算）
    @State private var highlightedReal: Int?  // 實際索引（用於高亮顯示與選取）
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

    /// 第一個功能在最右邊，依序往左排列，可無限循環
    private var ringItems: [FabRingItem] {
        if fab.currentFeatures.count > 1 {
            return fab.currentFeatures.map { feature in
                FabRingItem(id: feature.rawValue, icon: fab.icon(for: feature), title: fab.title(for: feature))
            }
        } else {
            return fab.actions.map { action in
                FabRingItem(id: action.id.uuidString, icon: action.systemImage, title: action.title)
            }
        }
    }

    var body: some View {
        ZStack {
            if isRingActive {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { dismissRing() }
                    .transition(.opacity)
            }

            fabButton
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }

    private var fabButton: some View {
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
            .onTapGesture {
                if isRingActive { dismissRing() }
            }
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        let f = geo.frame(in: .global)
                        fabGlobalCenter = CGPoint(x: f.midX, y: f.midY)
                    }
                    .onChange(of: geo.frame(in: .global)) { _, newFrame in
                        fabGlobalCenter = CGPoint(x: newFrame.midX, y: newFrame.midY)
                    }
                }
            )
            .overlay {
                if isRingActive {
                    FabRingView(
                        items: ringItems,
                        highlightedRealIndex: highlightedReal,
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

    // MARK: - Ring

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

    private func dismissRing() {
        stopScrollTimer()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            isRingActive = false
            highlightedVI = nil
            highlightedReal = nil
        }
        ringRotation = 0
    }

    // MARK: - Drag

    private func handleDrag(at location: CGPoint) {
        let dx = location.x - fabGlobalCenter.x
        let dy = location.y - fabGlobalCenter.y
        let distance = sqrt(dx * dx + dy * dy)

        guard distance > ringDeadZone else {
            if highlightedVI != nil {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    highlightedVI = nil
                    highlightedReal = nil
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

        var bestVI: Int?
        var bestDist: CGFloat = .infinity

        let count = items.count
        let sp = FabRingView.itemSpacing(for: count)
        let centerOffset = Int((FabRingView.arcStart - fingerAngle + ringRotation) / sp)

        for vi in (centerOffset - 6)...(centerOffset + 6) {
            let angle = FabRingView.angleFor(virtualIndex: vi, count: count, offset: ringRotation)
            let vis = FabRingView.itemVisibility(angle: angle)
            guard vis > 0.3 else { continue }

            let d = abs(FabRingView.normalizeAngle(fingerAngle - angle))
            if d < bestDist {
                bestDist = d
                bestVI = vi
            }
        }

        // 計算 realIndex 用於高亮顯示
        let bestReal: Int? = {
            guard let vi = bestVI, count > 0 else { return nil }
            return ((vi % count) + count) % count
        }()

        if bestVI != highlightedVI {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                highlightedVI = bestVI
                highlightedReal = bestReal
            }
            if bestVI != nil {
                let g = UIImpactFeedbackGenerator(style: .light)
                g.impactOccurred()
            }
        }
    }

    // MARK: - Edge Scroll

    private func checkEdgeScroll(fingerAngle: CGFloat) {
        // 項目少（≤5）時全部在弧形內，不需要邊緣滾動
        let itemCount = ringItems.count
        if itemCount <= 5 {
            stopScrollTimer()
            return
        }

        let arcMid = (FabRingView.arcStart + FabRingView.arcEnd) / 2
        let halfArc = FabRingView.arcSpan / 2

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
        let selectedReal = highlightedReal

        // 先快照要執行的資料，再關閉圓環
        let features = fab.currentFeatures
        let actions = fab.actions

        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            isRingActive = false
            highlightedVI = nil
            highlightedReal = nil
        }
        ringRotation = 0

        guard let realIdx = selectedReal else { return }

        let g = UIImpactFeedbackGenerator(style: .medium)
        g.impactOccurred()

        if features.count > 1 {
            // 主頁面：導航到功能（透過 fab.route）
            fab.route = .navigate(features[realIdx])
        } else {
            // 功能頁：透過 fab.route 觸發（跟主頁面走同一條路徑）
            guard realIdx < actions.count else { return }
            if let route = actions[realIdx].route {
                fab.route = route
            } else {
                actions[realIdx].action()
            }
            fab.collapse()
        }
    }
}

// MARK: - iPad 版（原本的膠囊選單）

private struct FabButtoniPad: View {
    @EnvironmentObject var fab: FabStore
    @EnvironmentObject private var theme: ThemeStore

    @State private var btnScale: CGFloat = 1.0
    @State private var btnRotation: Double = 0
    @State private var isAnimating = false
    @State private var showMenuItems: Bool = false
    @State private var showSubItems: Bool = false

    private let fabCircleSize: CGFloat = 60
    private let itemDelay: Double = 0.04

    private var fabCircleBg: Color {
        theme.isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.08)
    }
    private var pillBg: Color {
        theme.isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
    }
    private var pillStroke: Color {
        theme.isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }
    private var subPillBg: Color {
        theme.isDark ? Color.white.opacity(0.18) : Color.black.opacity(0.10)
    }
    private var fabForeground: Color {
        theme.isDark ? .white.opacity(0.95) : Color(.label)
    }
    private var menuForeground: Color {
        theme.isDark ? .white.opacity(0.92) : Color(.label)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack(alignment: .bottom, spacing: 12) {
                if fab.showSubMenu && fab.isExpanded {
                    subMenuView
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                mainMenuView
            }
            mainButton
        }
        .onChange(of: fab.isExpanded) { _, isExpanded in
            if !isExpanded && !isAnimating {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.80)) {
                    btnRotation = 0
                    btnScale = 1.0
                }
                showMenuItems = false
                showSubItems = false
            }
        }
    }

    @ViewBuilder private var mainMenuView: some View {
        if fab.isExpanded {
            VStack(alignment: .trailing, spacing: 8) {
                ForEach(fab.actions.indices, id: \.self) { index in
                    mainMenuItem(index: index, item: fab.actions[index])
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func mainMenuItem(index: Int, item: FabAction) -> some View {
        let isSelected: Bool = {
            guard let selected = fab.selectedFeature else { return false }
            return fab.title(for: selected) == item.title
        }()

        return Button {
            item.action()
        } label: {
            HStack(spacing: 8) {
                Text(item.title)
                    .font(.callout.weight(.semibold))
                Image(systemName: item.systemImage)
                    .font(.callout.weight(.semibold))
            }
            .foregroundStyle(menuForeground)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected
                ? (theme.isDark ? Color.white.opacity(0.28) : Color.black.opacity(0.14))
                : pillBg)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    isSelected
                        ? (theme.isDark ? Color.white.opacity(0.4) : Color.black.opacity(0.18))
                        : pillStroke,
                    lineWidth: isSelected ? 1.5 : 1
                )
            )
        }
        .buttonStyle(.plain)
        .opacity(showMenuItems ? 1 : 0)
        .offset(y: showMenuItems ? 0 : 14)
        .scaleEffect(showMenuItems ? 1 : 0.92, anchor: .trailing)
        .animation(
            .spring(response: 0.28, dampingFraction: 0.72)
            .delay(Double(index) * itemDelay),
            value: showMenuItems
        )
    }

    private var subMenuView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ForEach(fab.subActions.indices, id: \.self) { index in
                subMenuItem(index: index, item: fab.subActions[index])
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.26, dampingFraction: 0.72)) {
                showSubItems = true
            }
        }
    }

    private func subMenuItem(index: Int, item: FabAction) -> some View {
        Button {
            item.action()
        } label: {
            HStack(spacing: 8) {
                Text(item.title)
                    .font(.callout.weight(.semibold))
                Image(systemName: item.systemImage)
                    .font(.callout.weight(.semibold))
            }
            .foregroundStyle(menuForeground)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(subPillBg)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(
                theme.isDark ? Color.white.opacity(0.20) : Color.black.opacity(0.10),
                lineWidth: 1))
        }
        .buttonStyle(.plain)
        .opacity(showSubItems ? 1 : 0)
        .offset(x: showSubItems ? 0 : 16)
        .scaleEffect(showSubItems ? 1 : 0.92, anchor: .trailing)
        .animation(
            .spring(response: 0.26, dampingFraction: 0.72)
            .delay(Double(index) * itemDelay),
            value: showSubItems
        )
        .onChange(of: fab.showSubMenu) { _, isShowing in
            showSubItems = isShowing
        }
    }

    private var mainButton: some View {
        Button {
            if fab.isExpanded {
                collapseSequence()
            } else {
                expandSequence()
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(fabForeground)
                .frame(width: fabCircleSize, height: fabCircleSize)
                .background(fabCircleBg)
                .clipShape(Circle())
                .overlay(Circle().stroke(
                    theme.isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.08),
                    lineWidth: 1))
                .shadow(color: .black.opacity(theme.isDark ? 0.25 : 0.12), radius: 12, x: 0, y: 8)
                .scaleEffect(btnScale)
                .rotationEffect(.degrees(btnRotation))
                .accessibilityLabel(fab.isExpanded ? "收合選單" : "展開選單")
        }
        .buttonStyle(.plain)
        .disabled(isAnimating)
    }

    private func expandSequence() {
        guard !isAnimating else { return }
        isAnimating = true
        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.05)) { btnScale = 0.72 }
            try? await Task.sleep(nanoseconds: 80_000_000)
            fab.isExpanded = true
            showMenuItems = false
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                btnRotation = 135; btnScale = 1.28
            }
            showMenuItems = true
            try? await Task.sleep(nanoseconds: 70_000_000)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { btnScale = 1.0 }
            try? await Task.sleep(nanoseconds: 120_000_000)
            isAnimating = false
        }
    }

    private func collapseSequence() {
        guard !isAnimating else { return }
        isAnimating = true
        Task { @MainActor in
            showMenuItems = false
            showSubItems = false
            fab.hideSubMenu()
            let totalDelay = Double(max(fab.actions.count - 1, 0)) * itemDelay
            let waitForItems = UInt64((totalDelay + 0.04) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: waitForItems)
            withAnimation(.easeOut(duration: 0.05)) { btnScale = 0.72 }
            try? await Task.sleep(nanoseconds: 80_000_000)
            fab.isExpanded = false
            withAnimation(.spring(response: 0.22, dampingFraction: 0.80)) {
                btnRotation = 0; btnScale = 1.18
            }
            try? await Task.sleep(nanoseconds: 70_000_000)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { btnScale = 1.0 }
            try? await Task.sleep(nanoseconds: 120_000_000)
            isAnimating = false
        }
    }
}
