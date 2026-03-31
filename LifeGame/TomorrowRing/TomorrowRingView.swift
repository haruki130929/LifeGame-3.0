import SwiftUI

fileprivate let TOTAL_MINUTES = 1440
fileprivate let SNAP_STEP = 10   // ✅ 拖曳 10 分鐘一格

struct TomorrowRingView: View {
    enum Mode { case card, detail }

    @Binding var plan: TomorrowRingPlan
    @Binding var isInteracting: Bool
    @Binding var selectedItemID: UUID?
    var mode: Mode = .card
    var gameHP: Stat?
    var gameFP: Stat?

    @EnvironmentObject private var ringSettings: TomorrowRingSettingsStore

    init(
        plan: Binding<TomorrowRingPlan>,
        isInteracting: Binding<Bool> = .constant(false),
        selectedItemID: Binding<UUID?> = .constant(nil),
        mode: Mode = .card,
        gameHP: Stat? = nil,
        gameFP: Stat? = nil
    ) {
        self._plan = plan
        self._isInteracting = isInteracting
        self._selectedItemID = selectedItemID
        self.mode = mode
        self.gameHP = gameHP
        self.gameFP = gameFP
    }

    // MARK: - Constants
    private var ringLineWidth: CGFloat { mode == .detail ? 28 : 16 }
    private var hitWidth: CGFloat { ringLineWidth + 30 }

    // MARK: - Interaction State
    @State private var selectedID: UUID?
    @State private var dragStartMinute: Int?
    @State private var originalStartMinute: Int?
    @State private var hoveringItem: RingItem?
    @State private var workingItems: [RingItem] = []
    @State private var isDraggingRing = false

    var body: some View {
        VStack(spacing: 8) {
            ringCanvas
            infoLine
        }
        .onChange(of: selectedID) { _, newVal in
            if selectedItemID != newVal { selectedItemID = newVal }
        }
        .onChange(of: selectedItemID) { _, newVal in
            if selectedID != newVal { selectedID = newVal }
        }
    }
}

// MARK: - Ring Layer
private extension TomorrowRingView {
    enum RingLayer {
        case outer  // 表定行程（isFromSchedule）
        case inner  // 實際/臨時行程

        func inset(lineWidth: CGFloat, gap: CGFloat) -> CGFloat {
            switch self {
            case .outer: return 0
            case .inner: return lineWidth + gap
            }
        }
    }
}

// MARK: - Main Canvas
private extension TomorrowRingView {

    /// 兩圈之間的間距
    var ringGap: CGFloat { mode == .detail ? 10 : 6 }

    var currentItems: [RingItem] {
        isDraggingRing ? workingItems : plan.items
    }
    var outerItems: [RingItem] { currentItems.filter { $0.isFromSchedule } }
    var innerItems: [RingItem] { currentItems.filter { !$0.isFromSchedule } }

    var ringCanvas: some View {
        GeometryReader { geo in
            let rawSize = min(geo.size.width, geo.size.height)
            let detailScale: CGFloat = AppLayout.isIPad ? 0.70 : 0.85
            let size = mode == .detail ? rawSize * detailScale : rawSize
            let geoCenter = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let ringCenter = CGPoint(x: size / 2, y: size / 2)

            ZStack {
                // 外圈：虛線（未安排的部分）+ 彩色時段
                dashedGaps(items: outerItems, ringInset: 0)
                segments(items: outerItems, ringLayer: .outer)
            }
            .contentShape(Rectangle())
            .frame(width: size, height: size)
            .position(geoCenter)
        }
    }

    // MARK: - 虛線空隙（未安排時段的部分，圓條狀 + 虛線描邊）
    func dashedGaps(items: [RingItem], ringInset: CGFloat) -> some View {
        let gaps = computeGaps(from: items)
        let dashPattern: [CGFloat] = [5, 5]

        return ZStack {
            ForEach(gaps, id: \.0) { gapStart, gapEnd in
                ThickArcShape(
                    startMinute: gapStart,
                    endMinute: gapEnd,
                    totalMinutes: TOTAL_MINUTES,
                    thickness: ringLineWidth
                )
                .stroke(
                    .primary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 1.5, dash: dashPattern)
                )
                .padding(ringInset)
            }
        }
    }

    /// 從事件列表計算空閒時間區間（含 gap margin）
    func computeGaps(from items: [RingItem]) -> [(Int, Int)] {
        guard !items.isEmpty else {
            return [(0, TOTAL_MINUTES)] // 整圈都是空的
        }

        let margin = halfGap + 3  // 虛線圓條跟彩色時段之間的間隙
        let sorted = items.sorted { $0.startMinute < $1.startMinute }
        var gaps: [(Int, Int)] = []

        for i in 0..<sorted.count {
            let currentEnd = (sorted[i].endMinute + margin) % TOTAL_MINUTES
            let nextStart = (sorted[(i + 1) % sorted.count].startMinute - margin + TOTAL_MINUTES) % TOTAL_MINUTES

            let duration = (nextStart - currentEnd + TOTAL_MINUTES) % TOTAL_MINUTES
            if duration > 10 {
                gaps.append((currentEnd, nextStart))
            }
        }

        return gaps
    }

    // MARK: - 彩色時段
    var halfGap: Int { 3 }

    func segments(items: [RingItem], ringLayer: RingLayer) -> some View {
        let inset = ringLayer.inset(lineWidth: ringLineWidth, gap: ringGap)
        return ForEach(items) { item in
            segment(for: item, ringInset: inset)
                .zIndex(selectedID == item.id ? 10 : 0)
        }
    }

    func segment(for item: RingItem, ringInset: CGFloat) -> some View {
        let gapStart = (item.startMinute + halfGap) % TOTAL_MINUTES
        let gapEnd = (item.endMinute - halfGap + TOTAL_MINUTES) % TOTAL_MINUTES

        let thickArc = ThickArcShape(
            startMinute: gapStart,
            endMinute: gapEnd,
            totalMinutes: TOTAL_MINUTES,
            thickness: ringLineWidth
        )

        return ZStack {
            thickArc
                .fill(Color(hex: item.colorHex))
                .padding(ringInset)

            if selectedID == item.id {
                thickArc
                    .stroke(.primary.opacity(0.35), lineWidth: 2)
                    .padding(ringInset)
            }
        }
        .allowsHitTesting(true)
        .contentShape(Rectangle())
        .gesture(segmentInteractionGesture(item: item))
    }

    // MARK: - Icon
    var segmentIconSize: CGFloat { mode == .detail ? 11 : 6 }

    func segmentIcons(center: CGPoint, size: CGFloat, items: [RingItem], ringLayer: RingLayer) -> some View {
        let inset = ringLayer.inset(lineWidth: ringLineWidth, gap: ringGap)
        let r = size / 2 - inset
        return ZStack {
            ForEach(items) { item in
                let pos = pointOnRing(minute: item.startMinute, center: center, radius: r)
                Image(systemName: item.icon)
                    .font(.system(size: segmentIconSize, weight: .bold))
                    .foregroundStyle(.white)
                    .position(pos)
            }
        }
    }

    // MARK: - 選取高亮
    func selectionHighlight(for item: RingItem, ringLayer: RingLayer) -> some View {
        let gapStart = (item.startMinute + halfGap) % TOTAL_MINUTES
        let gapEnd = (item.endMinute - halfGap + TOTAL_MINUTES) % TOTAL_MINUTES
        let inset = ringLayer.inset(lineWidth: ringLineWidth, gap: ringGap)

        let thickArc = ThickArcShape(
            startMinute: gapStart,
            endMinute: gapEnd,
            totalMinutes: TOTAL_MINUTES,
            thickness: ringLineWidth + 6
        )

        return thickArc
            .stroke(.primary.opacity(0.3), lineWidth: 2)
            .padding(inset - 3)
    }

    // MARK: - 中間圓圈
    func centerCircle(size: CGFloat) -> some View {
        let innerInset = RingLayer.inner.inset(lineWidth: ringLineWidth, gap: ringGap)
        let innerRadius = size / 2 - innerInset - ringLineWidth / 2
        let circleSize = innerRadius * 2 * 0.82

        return ZStack {
            Circle()
                .fill(.primary.opacity(0.08))
                .overlay(
                    Circle().stroke(.primary.opacity(0.25), lineWidth: 1.5)
                )
                .frame(width: circleSize, height: circleSize)

            VStack(spacing: mode == .detail ? 8 : 4) {
                if mode == .detail {
                    Text(currentTimeString)
                        .font(.title2.bold())
                        .monospacedDigit()
                }

                if let hp = gameHP, let fp = gameFP {
                    statRow(label: "HP", current: hp.current, max: hp.max, color: .red)
                    statRow(label: "FP", current: fp.current, max: fp.max, color: .blue)
                } else {
                    VStack(spacing: 2) {
                        Text("HP \(plan.remainingHP)")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                        Text("FP \(plan.remainingFP)")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }

    func statRow(label: String, current: Int, max: Int, color: Color) -> some View {
        VStack(spacing: 3) {
            Text("\(label) \(current)/\(max)")
                .font(.caption.bold())
                .monospacedDigit()

            GeometryReader { geo in
                let ratio = max > 0 ? CGFloat(current) / CGFloat(max) : 0
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.18))
                    Capsule().fill(color).frame(width: geo.size.width * ratio)
                }
            }
            .frame(width: 56, height: 5)
            .clipShape(Capsule())
        }
    }

    var currentTimeString: String {
        let cal = Calendar.current
        let now = Date()
        return String(format: "%02d:%02d",
                      cal.component(.hour, from: now),
                      cal.component(.minute, from: now))
    }

    // MARK: - 時間紅線
    var currentTimeNeedle: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let r = size / 2

            let cal = Calendar.current
            let now = Date()
            let minute = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
            let angle = CGFloat(minute) / CGFloat(TOTAL_MINUTES) * 2 * .pi - .pi / 2

            let totalInset = RingLayer.inner.inset(lineWidth: ringLineWidth, gap: ringGap)
            let innerR = r - totalInset - ringLineWidth / 2 - 4
            let outerR = r + ringLineWidth / 2 + 2

            let p1 = CGPoint(x: center.x + cos(angle) * innerR,
                             y: center.y + sin(angle) * innerR)
            let p2 = CGPoint(x: center.x + cos(angle) * outerR,
                             y: center.y + sin(angle) * outerR)

            Path { path in
                path.move(to: p1)
                path.addLine(to: p2)
            }
            .stroke(.red, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
    }

    // MARK: - Helpers
    func pointOnRing(minute: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = CGFloat(minute) / CGFloat(TOTAL_MINUTES) * 2 * .pi - .pi / 2
        return CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }
}

// MARK: - Bottom Info Line
private extension TomorrowRingView {

    @ViewBuilder
    var infoLine: some View {
        if let item = hoveringItem {
            Text("\(item.title)  \(minuteText(item.startMinute)) 〜 \(minuteText(item.endMinute))")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .lineLimit(1)
        } else if mode == .card {
            Text("長按一段再沿圓形拖曳")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Gesture
private extension TomorrowRingView {

    func beginInteraction(selecting item: RingItem) {
        selectedID = item.id
        hoveringItem = item
        isInteracting = true
        isDraggingRing = true
        workingItems = plan.items
        resetDragState()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func handleDragChange(_ location: CGPoint, center: CGPoint) {
        guard let id = selectedID else { return }
        isInteracting = true

        let currentMinute = snapToStep(
            minuteFromTouch(location, center: center),
            step: SNAP_STEP
        )

        if dragStartMinute == nil {
            dragStartMinute = currentMinute
            let baseStart =
                workingItems.first(where: { $0.id == id })?.startMinute
                ?? plan.items.first(where: { $0.id == id })?.startMinute
                ?? 0
            originalStartMinute = snapToStep(baseStart, step: SNAP_STEP)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }

        guard let dragStartMinute, let originalStartMinute else { return }
        let base = workingItems.first(where: { $0.id == id })
            ?? plan.items.first(where: { $0.id == id })
        guard let base else { return }

        let duration = positiveDuration(from: base.startMinute, to: base.endMinute)
        let delta = currentMinute - dragStartMinute
        let rawStart = mod(originalStartMinute + delta, TOTAL_MINUTES)
        let newStart = snapToStep(rawStart, step: SNAP_STEP)
        let newEnd = mod(newStart + duration, TOTAL_MINUTES)

        updateWorkingItem(id: id, start: newStart, end: newEnd)
        hoveringItem = workingItems.first(where: { $0.id == id })
    }

    func endDragCommit() {
        guard selectedID != nil else { return }
        resetDragState()
        commitWorkingToPlan()
        isDraggingRing = false
        isInteracting = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func resetDragState() {
        dragStartMinute = nil
        originalStartMinute = nil
    }

    func clearSelection() {
        selectedID = nil
        hoveringItem = nil
        resetDragState()
        isInteracting = false
        isDraggingRing = false
    }

    func segmentInteractionGesture(item: RingItem) -> some Gesture {
        LongPressGesture(minimumDuration: 0.15)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { phase in
                switch phase {
                case .first(true):
                    beginInteraction(selecting: item)
                case .second(true, let drag?):
                    handleDragChange(drag.location, center: .zero)
                default:
                    break
                }
            }
            .onEnded { _ in
                endDragCommit()
            }
    }
}

// MARK: - Plan Update
private extension TomorrowRingView {

    func updateWorkingItem(id: UUID, start: Int, end: Int) {
        guard let idx = workingItems.firstIndex(where: { $0.id == id }) else { return }
        workingItems[idx].startMinute = start
        workingItems[idx].endMinute = end
    }

    func commitWorkingToPlan() {
        let tx = Transaction(animation: nil)
        withTransaction(tx) {
            plan.items = workingItems
            plan.items.sort { $0.startMinute < $1.startMinute }
        }
    }
}

// MARK: - Time / Math Helpers
private extension TomorrowRingView {

    func minuteFromTouch(_ p: CGPoint, center: CGPoint) -> Int {
        let dx = p.x - center.x
        let dy = p.y - center.y
        var angle = atan2(dy, dx)
        angle += .pi / 2
        if angle < 0 { angle += 2 * .pi }
        let fraction = angle / (2 * .pi)
        let minute = Int(round(fraction * Double(TOTAL_MINUTES)))
        return clamp(minute, 0, TOTAL_MINUTES - 1)
    }

    func positiveDuration(from start: Int, to end: Int) -> Int {
        let d = end - start
        return d >= 0 ? d : (d + TOTAL_MINUTES)
    }

    func mod(_ x: Int, _ m: Int) -> Int {
        let r = x % m
        return r >= 0 ? r : (r + m)
    }

    func midpointMinute(start: Int, end: Int) -> Int {
        let dur = positiveDuration(from: start, to: end)
        return (start + dur / 2) % TOTAL_MINUTES
    }

    func minuteText(_ m: Int) -> String {
        let mm = (m % TOTAL_MINUTES + TOTAL_MINUTES) % TOTAL_MINUTES
        return String(format: "%02d:%02d", mm / 60, mm % 60)
    }
}

// MARK: - File-level Helpers
fileprivate func snapToStep(_ m: Int, step: Int) -> Int {
    let snapped = Int(round(Double(m) / Double(step))) * step
    return clamp(snapped, 0, TOTAL_MINUTES - step)
}

fileprivate func clamp(_ x: Int, _ a: Int, _ b: Int) -> Int {
    min(max(x, a), b)
}
