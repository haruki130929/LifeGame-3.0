import Foundation
import SwiftUI

// MARK: - RingTimeHelpers

/// Centralized time/angle math for the ring. Eliminates duplication across files.
enum RingTimeHelpers {
    static let totalMinutes = 1440
    static let snapStep = 10 // minutes

    // MARK: - Minute ↔ Angle

    /// Convert minute (0..<1440) to angle in radians. 0 min = 12 o'clock (top).
    static func angle(for minute: Int) -> Double {
        Double(minute) / Double(totalMinutes) * 2 * .pi
    }

    /// Convert angle (radians, 0 = 12 o'clock clockwise) to minute.
    static func minute(for angle: Double) -> Int {
        let normalized = ((angle / (2 * .pi)).truncatingRemainder(dividingBy: 1.0) + 1.0)
            .truncatingRemainder(dividingBy: 1.0)
        return Int(normalized * Double(totalMinutes))
    }

    // MARK: - Touch → Minute

    /// Convert a touch point relative to ring center into a minute value.
    static func minute(from point: CGPoint, center: CGPoint) -> Int {
        let dx = point.x - center.x
        let dy = point.y - center.y
        var angle = atan2(dx, -dy) // 12 o'clock = 0, clockwise positive
        if angle < 0 { angle += 2 * .pi }
        return minute(for: angle)
    }

    // MARK: - Snap

    /// Snap a minute value to the nearest grid step.
    static func snap(_ minute: Int, step: Int = snapStep) -> Int {
        let snapped = ((minute + step / 2) / step) * step
        return snapped % totalMinutes
    }

    // MARK: - Duration

    /// Compute duration handling midnight wrap.
    static func duration(from start: Int, to end: Int) -> Int {
        let d = end - start
        return d >= 0 ? d : d + totalMinutes
    }

    // MARK: - Point on circle

    /// Point at given angle and radius from center.
    static func point(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        CGPoint(
            x: center.x + radius * CGFloat(sin(angle)),
            y: center.y - radius * CGFloat(cos(angle))
        )
    }

    // MARK: - Minute → Display String

    /// Format minute as "HH:mm".
    static func timeString(for minute: Int) -> String {
        let h = (minute / 60) % 24
        let m = minute % 60
        return String(format: "%02d:%02d", h, m)
    }

    // MARK: - Date ↔ Minute

    static func minute(from date: Date) -> Int {
        let cal = Calendar.current
        return cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
    }

    static func date(from minute: Int, reference: Date = Date()) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: reference)
        comps.hour = (minute / 60) % 24
        comps.minute = minute % 60
        return cal.date(from: comps) ?? reference
    }

    // MARK: - Contains (arc range check)

    /// Check if a minute falls within a circular arc [start, end).
    static func arcContains(start: Int, end: Int, minute: Int) -> Bool {
        if start < end {
            return minute >= start && minute < end
        } else { // wraps midnight
            return minute >= start || minute < end
        }
    }
}
