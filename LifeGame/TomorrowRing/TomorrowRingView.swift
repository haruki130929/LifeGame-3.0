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
    private var ringLineWidth: CGFloat { mode == .detail ? 32 : 18 }
    private var hitWidth: CGFloat { ringLineWidth + 30 }

    // MARK: - Interaction State
    // ✅ 內部用 @State，手勢邏輯不受 .constant binding 影響
    @State private var selectedID: UUID?
    @State private var dragStartMinute: Int?
    @State private var originalStartMinute: Int?
    @State private var hoveringItem: RingItem?

    // ✅ 拖曳中只改這份，不卡
    @State private var workingItems: [RingItem] = []
    @State private var isDraggingRing = false

    var body: some View {
        VStack(spacing: 8) {
            ringCanvas

            infoLine
        }
        // ✅ 雙向同步：內部 selectedID ↔ 外部 selectedItemID
        .onChange(of: selectedID) { _, newVal in
            if selectedItemID != newVal { selectedItemID = newVal }
        }
        .onChange(of: selectedItemID) { _, newVal in
            if selectedID != newVal { selectedID = newVal }
        }
    }
}

// MARK: - Main Canvas
private extension TomorrowRingView {
    
    var ringCanvas: some View {
        GeometryReader { geo in
            let rawSize = min(geo.size.width, geo.size.height)
            let size = mode == .detail ? rawSize * 0.70 : rawSize
            let geoCenter = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            // ✅ 手勢座標是相對於 ZStack（size × size），圓心在正中央
            let ringCenter = CGPoint(x: size / 2, y: size / 2)

            ZStack {
                // ✅ 取消點選：選中時點空白處取消；未選中時不攔截（避免擋住 NavigationLink）
                Color.clear
                    .contentShape(Rectangle())
                    .allowsHitTesting(selectedID != nil)
                    .onTapGesture { clearSelection() }

                baseRing

                RingTimeTicks(
                    tickEvery: 30,
                    majorTickEvery: 60,
                    ringLineWidth: ringLineWidth,
                    minorTickLen: Layout.isIPad ? 22 : 17,
                    majorTickLen: Layout.isIPad ? 25 : 20
                )
                .allowsHitTesting(false)

                RingHourLabels(
                    labelRadiusRatio: mode == .detail ? 0.76 : 0.68,
                    font: .caption
                )
                .allowsHitTesting(false)

                if let id = selectedID,
                   let item = currentItems.first(where: { $0.id == id }) {
                    RingSelectionMarkers(
                        startMinute: item.startMinute,
                        endMinute: item.endMinute,
                        color: Color(hex: item.colorHex),
                        markerRadiusRatio: 0.94,
                        markerLen: 12,
                        lineWidth: 3,
                        strokeOpacity: 0.25
                    )
                    .allowsHitTesting(false)
                }

                segments(center: ringCenter, items: currentItems)

                if mode == .detail, ringSettings.showSegmentIcons {
                    segmentIcons(center: ringCenter, size: size, items: currentItems)
                        .allowsHitTesting(false)
                }

                currentTimeNeedle
                    .allowsHitTesting(false)
                centerInfo
            }
            // ✅ 這個讓拖曳手勢固定吃到（ScrollView 不會搶）
            .contentShape(Rectangle())
            .frame(width: size, height: size)
            .position(geoCenter)
        }
    }
    
    var currentItems: [RingItem] {
        isDraggingRing ? workingItems : plan.items
    }
    
    var baseRing: some View {
        Circle()
            .stroke(.primary.opacity(0.13), lineWidth: ringLineWidth)
    }
    
    func segments(center: CGPoint, items: [RingItem]) -> some View {
        ForEach(items) { item in
            segment(for: item, center: center)
                .zIndex(selectedID == item.id ? 10 : 0)
        }
    }

    func segmentIcons(center: CGPoint, size: CGFloat, items: [RingItem]) -> some View {
        let r = size / 2
        return ZStack {
            ForEach(items) { item in
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary.opacity(0.9))
                    .position(iconPosition(for: item, center: center, radius: r))
            }
        }
    }

    func iconPosition(for item: RingItem, center: CGPoint, radius: CGFloat) -> CGPoint {
        // 靠近時段起始端（左側 20%）
        let dur = positiveDuration(from: item.startMinute, to: item.endMinute)
        let offsetMinute = (item.startMinute + dur / 16) % TOTAL_MINUTES
        let angle = CGFloat(offsetMinute) / CGFloat(TOTAL_MINUTES) * 2 * .pi - .pi / 2
        return CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }
    
    func segment(for item: RingItem, center: CGPoint) -> some View {
        let arc = ArcShape(
            startMinute: item.startMinute,
            endMinute: item.endMinute,
            totalMinutes: TOTAL_MINUTES
        )
        
        return ZStack {
            arc.stroke(
                Color(hex: item.colorHex),
                style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
            )

            if selectedID == item.id {
                arc.stroke(
                    .primary.opacity(0.35),
                    style: StrokeStyle(lineWidth: ringLineWidth + 5, lineCap: .round)
                )
            }
        }
        .contentShape(
            arc.stroke(style: StrokeStyle(lineWidth: hitWidth, lineCap: .round))
        )
        .gesture(segmentInteractionGesture(item: item, center: center))
    }
    
    var centerInfo: some View {
        VStack(spacing: 6) {
            if mode == .detail {
                Text(currentTimeString)
                    .font(.title.bold())
                    .monospacedDigit()
            }

            if let hp = gameHP, let fp = gameFP {
                statRow(label: "HP", current: hp.current, max: hp.max, color: .red)
                statRow(label: "FP", current: fp.current, max: fp.max, color: .blue)
            } else {
                Text("HP \(plan.remainingHP)  FP \(plan.remainingFP)")
                    .font(.headline)
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
                    Capsule()
                        .fill(color.opacity(0.18))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * ratio)
                }
            }
            .frame(width: 60, height: 5)
            .clipShape(Capsule())
        }
    }

    var currentTimeString: String {
        let cal = Calendar.current
        let now = Date()
        let h = cal.component(.hour, from: now)
        let m = cal.component(.minute, from: now)
        return String(format: "%02d:%02d", h, m)
    }

    // MARK: - 現在時間紅線
    var currentTimeNeedle: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let r = size / 2

            let cal = Calendar.current
            let now = Date()
            let minute = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
            let angle = CGFloat(minute) / CGFloat(TOTAL_MINUTES) * 2 * .pi - .pi / 2

            let innerR = r * 0.72
            let outerR = r + ringLineWidth / 2
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
        
        let base =
        workingItems.first(where: { $0.id == id })
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
    func segmentInteractionGesture(item: RingItem, center: CGPoint) -> some Gesture {
        LongPressGesture(minimumDuration: 0.15)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { phase in
                switch phase {
                case .first(true):
                    // ✅ 長按成立那一刻才進入互動
                    beginInteraction(selecting: item)
                    
                case .second(true, let drag?):
                    // ✅ 長按後開始拖曳
                    handleDragChange(drag.location, center: center)
                    
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
            // ✅ 只在放手後排序一次
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
        let h = mm / 60
        let min = mm % 60
        return String(format: "%02d:%02d", h, min)
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
