import SwiftUI

// MARK: - DualRingCanvas

/// The main dual-ring view: inner ring (plan) + outer ring (actual).
/// No continuous track — segments are capsule-shaped arcs with gaps between them.
struct DualRingCanvas: View {
    @EnvironmentObject private var store: TomorrowRingStore

    enum Mode { case card, detail }
    var mode: Mode = .detail

    /// External binding for selected item coordination.
    @Binding var selectedItemID: UUID?

    /// Callback when user taps "+" on a gap segment.
    var onAddInGap: ((_ ring: ActiveRing, _ startMinute: Int, _ endMinute: Int) -> Void)?

    /// Which ring is being edited.
    enum ActiveRing { case plan, actual }
    @State private var activeRing: ActiveRing = .plan

    // MARK: - Drag state

    @State private var isDragging = false
    @State private var dragItemID: UUID?
    @State private var workingPlanItems: [RingItemV2] = []
    @State private var workingActualItems: [RingItemV2] = []

    // MARK: - Long press tracking

    @State private var pressStartLocation: CGPoint?
    @State private var longPressTask: Task<Void, Never>?
    private let longPressDuration: TimeInterval = 0.3

    // MARK: - Layout constants

    private var innerLineWidth: CGFloat { mode == .card ? 10 : 28 }
    private var outerLineWidth: CGFloat { mode == .card ? 12 : 32 }
    private var ringGap: CGFloat { mode == .card ? 6 : 10 }
    private let segmentGapDegrees: Double = 2.5  // extra visual gap on top of cap inset
    private let floatScale: CGFloat = 1.08
    private let iconSize: CGFloat = 14

    /// Whether any segment is selected or being dragged (hides "+" buttons)
    private var isInteracting: Bool {
        isDragging || selectedItemID != nil
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            let edgeInset: CGFloat = mode == .card ? 10 : 28
            let outerRadius = size / 2 - outerLineWidth / 2 - edgeInset
            let innerRadius = outerRadius - outerLineWidth / 2 - ringGap - innerLineWidth / 2

            ZStack {
                // Hour labels
                if mode == .detail {
                    RingHourLabelsV2(
                        radius: outerRadius,
                        center: center,
                        labelRadius: outerRadius + outerLineWidth / 2 + 14
                    )
                }

                // Tick marks
                RingTimeTicksV2(radius: outerRadius + outerLineWidth / 2, center: center)

                // Inner ring (Plan)
                ringLayer(
                    items: isDragging && activeRing == .plan ? workingPlanItems : store.plan.planItems,
                    radius: innerRadius,
                    lineWidth: innerLineWidth,
                    center: center,
                    opacity: activeRing == .actual ? 0.5 : 1.0,
                    ring: .plan
                )

                // Outer ring (Actual)
                ringLayer(
                    items: isDragging && activeRing == .actual ? workingActualItems : store.plan.actualItems,
                    radius: outerRadius,
                    lineWidth: outerLineWidth,
                    center: center,
                    opacity: activeRing == .plan ? 0.5 : 1.0,
                    ring: .actual
                )

                // Current time needle
                RingNeedle(
                    center: center,
                    innerRadius: innerRadius - innerLineWidth / 2,
                    outerRadius: outerRadius + outerLineWidth / 2
                )

                // Center info
                centerInfo
                    .position(center)
            }
            .contentShape(Circle())
            .gesture(mode == .detail ? touchGesture(center: center, innerRadius: innerRadius, outerRadius: outerRadius) : nil)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Cap inset calculation

    /// Compute how many minutes the rounded cap extends beyond the arc.
    /// Cap width = lineWidth/2, arc length per minute = 2π·radius/1440.
    /// So cap covers (lineWidth/2) / (2π·radius/1440) minutes.
    private func capInsetMinutes(radius: CGFloat, lineWidth: CGFloat) -> Int {
        let capLength = lineWidth / 2
        let minutesPerPoint = Double(RingTimeHelpers.totalMinutes) / (2 * .pi * Double(radius))
        return Int((Double(capLength) * minutesPerPoint).rounded())
    }

    // MARK: - Ring Layer

    @ViewBuilder
    private func ringLayer(
        items: [RingItemV2],
        radius: CGFloat,
        lineWidth: CGFloat,
        center: CGPoint,
        opacity: Double,
        ring: ActiveRing
    ) -> some View {
        // Inset = cap overhang only, so adjacent round caps just touch without overlapping
        let totalInset = capInsetMinutes(radius: radius, lineWidth: lineWidth)

        let gaps = RingCollisionEngine.gapSegments(items: items)

        // Dashed gap segments
        ForEach(Array(gaps.enumerated()), id: \.offset) { _, gap in
            let gapDuration = RingTimeHelpers.duration(from: gap.start, to: gap.end)

            DashedArcOutline(
                startMinute: gap.start,
                endMinute: gap.end,
                baseRadius: radius,
                bandWidth: lineWidth
            )
            .frame(width: radius * 2 + lineWidth * 2, height: radius * 2 + lineWidth * 2)
            .position(center)
            .opacity(opacity)

            // "+" button — hidden when any segment is selected or being dragged
            if mode == .detail && gapDuration > 30 && !isInteracting {
                let midMinute = (gap.start + gapDuration / 2) % RingTimeHelpers.totalMinutes
                let midAngle = RingTimeHelpers.angle(for: midMinute)
                let midPos = RingTimeHelpers.point(center: center, radius: radius, angle: midAngle)

                Button {
                    onAddInGap?(ring, gap.start, gap.end)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }
                .position(midPos)
                .opacity(opacity * 0.8)
                .transition(.opacity)
            }
        }

        // Filled segments with icons
        ForEach(items) { item in
            let isBeingDragged = isDragging && item.id == dragItemID

            // Inset arc start/end by cap size so round caps land at the original minute boundaries
            ArcShapeV2(
                startMinute: (item.startMinute + totalInset) % RingTimeHelpers.totalMinutes,
                endMinute: (item.endMinute - totalInset + RingTimeHelpers.totalMinutes) % RingTimeHelpers.totalMinutes
            )
            .stroke(
                Color(hex: item.colorHex),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: radius * 2, height: radius * 2)
            .position(center)
            .opacity(opacity)
            .scaleEffect(isBeingDragged ? floatScale : 1.0)
            .shadow(
                color: isBeingDragged
                    ? Color(hex: item.colorHex).opacity(0.6) : .clear,
                radius: isBeingDragged ? 12 : 0
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isBeingDragged)

            // Icon near the start of the arc (offset inward a bit)
            if mode == .detail && item.duration >= 20 {
                let iconOffsetMinutes = max(item.duration / 8, totalInset + 6)
                let iconMinute = (item.startMinute + iconOffsetMinutes) % RingTimeHelpers.totalMinutes
                let iconAngle = RingTimeHelpers.angle(for: iconMinute)
                let iconPos = RingTimeHelpers.point(center: center, radius: radius, angle: iconAngle)

                Image(systemName: item.icon)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    .position(iconPos)
                    .opacity(opacity)
                    .allowsHitTesting(false)
                    .scaleEffect(isBeingDragged ? floatScale : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isBeingDragged)
            }
        }
    }

    // MARK: - Center Info

    private var centerInfo: some View {
        VStack(spacing: mode == .card ? 6 : 8) {
            // Live updating time (uses app's default font)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(RingTimeHelpers.timeString(for: RingTimeHelpers.minute(from: context.date)))
                    .font(mode == .card ? .title2.weight(.bold) : .title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }

            VStack(spacing: mode == .card ? 4 : 5) {
                StatBar(
                    label: "HP",
                    current: store.plan.remainingHP,
                    max: store.plan.baseHP,
                    color: .red,
                    compact: mode == .card
                )
                StatBar(
                    label: "FP",
                    current: store.plan.remainingFP,
                    max: store.plan.baseFP,
                    color: .orange,
                    compact: mode == .card
                )
            }
            .frame(width: mode == .card ? 100 : 110)
        }
    }

    // MARK: - Touch Gesture (DragGesture + long-press timer)

    private func touchGesture(center: CGPoint, innerRadius: CGFloat, outerRadius: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if pressStartLocation == nil {
                    // First touch — start long press timer
                    pressStartLocation = value.location
                    let touchLoc = value.location
                    longPressTask?.cancel()
                    longPressTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: UInt64(longPressDuration * 1_000_000_000))
                        guard !Task.isCancelled, !isDragging else { return }
                        // Long press succeeded — lift the item at the original touch location
                        let touchMinute = RingTimeHelpers.minute(from: touchLoc, center: center)
                        beginDrag(touchMinute: touchMinute, center: center,
                                  innerRadius: innerRadius, outerRadius: outerRadius,
                                  touchPoint: touchLoc)
                    }
                    return
                }

                // If finger moved significantly before long press, cancel it
                if let start = pressStartLocation, !isDragging {
                    let dx = value.location.x - start.x
                    let dy = value.location.y - start.y
                    if hypot(dx, dy) > 10 {
                        longPressTask?.cancel()
                        pressStartLocation = nil
                    }
                }

                // If already dragging, update position
                if isDragging {
                    let touchMinute = RingTimeHelpers.minute(from: value.location, center: center)
                    updateDrag(touchMinute: touchMinute)
                }
            }
            .onEnded { _ in
                longPressTask?.cancel()
                longPressTask = nil
                pressStartLocation = nil
                endDrag()
            }
    }

    private func beginDrag(touchMinute: Int, center: CGPoint,
                           innerRadius: CGFloat, outerRadius: CGFloat,
                           touchPoint: CGPoint) {
        let dist = hypot(touchPoint.x - center.x, touchPoint.y - center.y)
        let innerRange = (innerRadius - innerLineWidth)...(innerRadius + innerLineWidth)
        let outerRange = (outerRadius - outerLineWidth)...(outerRadius + outerLineWidth)

        let items: [RingItemV2]
        if outerRange.contains(dist) {
            activeRing = .actual
            items = store.plan.actualItems
        } else if innerRange.contains(dist) {
            activeRing = .plan
            items = store.plan.planItems
        } else {
            return
        }

        // Find which item is at this minute
        guard let hit = items.first(where: {
            RingTimeHelpers.arcContains(start: $0.startMinute, end: $0.endMinute, minute: touchMinute)
        }) else { return }

        // Haptic feedback on successful long press
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            isDragging = true
            dragItemID = hit.id
            selectedItemID = hit.id
        }
        workingPlanItems = store.plan.planItems
        workingActualItems = store.plan.actualItems
    }

    private func updateDrag(touchMinute: Int) {
        guard let dragID = dragItemID else { return }

        let items: [RingItemV2]
        switch activeRing {
        case .plan: items = workingPlanItems
        case .actual: items = workingActualItems
        }

        guard let idx = items.firstIndex(where: { $0.id == dragID }) else { return }
        var item = items[idx]
        let dur = item.duration
        let snapped = RingTimeHelpers.snap(touchMinute - dur / 2)
        let newEnd = (snapped + dur) % RingTimeHelpers.totalMinutes

        // Check collision
        var testItem = item
        testItem.startMinute = snapped
        testItem.endMinute = newEnd
        let others = items.filter { $0.id != dragID }

        if RingCollisionEngine.findCollision(for: testItem, among: others) == nil {
            item.startMinute = snapped
            item.endMinute = newEnd

            switch activeRing {
            case .plan:
                workingPlanItems[idx] = item
            case .actual:
                workingActualItems[idx] = item
            }
        }
    }

    private func endDrag() {
        guard isDragging else { return }

        // Commit changes
        switch activeRing {
        case .plan:
            store.planUndoManager.push(store.plan.planItems)
            store.plan.planItems = workingPlanItems.sorted { $0.startMinute < $1.startMinute }
        case .actual:
            store.actualUndoManager.push(store.plan.actualItems)
            store.plan.actualItems = workingActualItems.sorted { $0.startMinute < $1.startMinute }
        }

        // Release — segment snaps back to track, "+" buttons reappear
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isDragging = false
            dragItemID = nil
            selectedItemID = nil
        }
    }
}

// MARK: - StatBar

private struct StatBar: View {
    let label: String
    let current: Int
    let max: Int
    let color: Color
    var compact: Bool = false

    private var progress: Double {
        max > 0 ? Double(current) / Double(max) : 0
    }

    var body: some View {
        HStack(spacing: compact ? 5 : 6) {
            Text(label)
                .font(compact ? .caption2.weight(.bold) : .caption2.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: compact ? 18 : 16, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.15))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: compact ? 5 : 5)
        }
    }
}

