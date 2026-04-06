import Foundation

// MARK: - RingCollisionEngine

enum RingCollisionEngine {

    enum CollisionError: Error, LocalizedError {
        case overlapping(existingTitle: String)
        case noValidPosition

        var errorDescription: String? {
            switch self {
            case .overlapping(let title):
                return "與「\(title)」時段重疊"
            case .noValidPosition:
                return "找不到可用的時間位置"
            }
        }
    }

    // MARK: - Overlap check

    /// Check if two arcs on a 1440-minute ring overlap.
    static func arcsOverlap(s1: Int, e1: Int, s2: Int, e2: Int) -> Bool {
        // Empty arcs don't overlap
        if s1 == e1 || s2 == e2 { return false }

        let total = RingTimeHelpers.totalMinutes
        let e2prev = (e2 - 1 + total) % total
        let e1prev = (e1 - 1 + total) % total

        return RingTimeHelpers.arcContains(start: s1, end: e1, minute: s2)
            || RingTimeHelpers.arcContains(start: s1, end: e1, minute: e2prev)
            || RingTimeHelpers.arcContains(start: s2, end: e2, minute: s1)
            || RingTimeHelpers.arcContains(start: s2, end: e2, minute: e1prev)
    }

    // MARK: - Validate item against others

    /// Check if an item collides with any existing items (excluding itself by ID).
    static func findCollision(
        for item: RingItemV2,
        among items: [RingItemV2]
    ) -> RingItemV2? {
        for other in items where other.id != item.id {
            if arcsOverlap(
                s1: item.startMinute, e1: item.endMinute,
                s2: other.startMinute, e2: other.endMinute
            ) {
                return other
            }
        }
        return nil
    }

    /// Validate that an item doesn't collide. Returns .success or .failure with the colliding item's title.
    static func validate(
        item: RingItemV2,
        among items: [RingItemV2]
    ) -> Result<Void, CollisionError> {
        if let collision = findCollision(for: item, among: items) {
            return .failure(.overlapping(existingTitle: collision.title))
        }
        return .success(())
    }

    // MARK: - Find nearest valid position

    /// During drag, find the nearest non-colliding start position.
    /// Scans outward from `desiredStart` in both directions.
    static func nearestValidStart(
        for item: RingItemV2,
        desiredStart: Int,
        among items: [RingItemV2],
        snapStep: Int = RingTimeHelpers.snapStep,
        maxSearch: Int = 120 // max minutes to scan
    ) -> Int? {
        let dur = item.duration
        let total = RingTimeHelpers.totalMinutes

        // Try desired position first
        let testEnd = (desiredStart + dur) % total
        var test = item
        test.startMinute = desiredStart
        test.endMinute = testEnd
        if findCollision(for: test, among: items) == nil {
            return desiredStart
        }

        // Scan outward
        for offset in stride(from: snapStep, through: maxSearch, by: snapStep) {
            // Try forward
            let fwd = (desiredStart + offset) % total
            let fwdEnd = (fwd + dur) % total
            test.startMinute = fwd
            test.endMinute = fwdEnd
            if findCollision(for: test, among: items) == nil {
                return fwd
            }

            // Try backward
            let bwd = (desiredStart - offset + total) % total
            let bwdEnd = (bwd + dur) % total
            test.startMinute = bwd
            test.endMinute = bwdEnd
            if findCollision(for: test, among: items) == nil {
                return bwd
            }
        }

        return nil
    }

    // MARK: - Gap segments (for dashed empty arcs)

    /// Compute the gap segments between filled items on the ring.
    /// Returns array of (startMinute, endMinute) for empty arcs.
    /// Only returns gaps that are visually meaningful (> minGapMinutes).
    static func gapSegments(
        items: [RingItemV2],
        gapDegrees: Double = 2.0,
        minGapMinutes: Int = 20
    ) -> [(start: Int, end: Int)] {
        guard !items.isEmpty else {
            return [(start: 0, end: RingTimeHelpers.totalMinutes)]
        }

        let total = RingTimeHelpers.totalMinutes
        let padMinutes = Int(gapDegrees / 360.0 * Double(total))
        let sorted = items.sorted { $0.startMinute < $1.startMinute }
        var gaps: [(start: Int, end: Int)] = []

        for i in 0..<sorted.count {
            let currentEnd = sorted[i].endMinute
            let nextStart = sorted[(i + 1) % sorted.count].startMinute

            // Raw gap between two segments
            let rawDuration = RingTimeHelpers.duration(from: currentEnd, to: nextStart)

            // Skip if gap is too small to show a dashed segment
            guard rawDuration > minGapMinutes else { continue }

            // Inset by padding so dashed segment doesn't overlap filled arcs
            let gapStart = (currentEnd + padMinutes) % total
            let gapEnd = (nextStart - padMinutes + total) % total

            gaps.append((start: gapStart, end: gapEnd))
        }

        return gaps
    }
}
