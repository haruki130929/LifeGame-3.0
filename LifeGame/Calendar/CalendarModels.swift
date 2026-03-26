import SwiftUI

// MARK: - Calendar 共用 Model

struct CalendarRange: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let color: Color
    var eventId: UUID? = nil
}

struct RangeSegment: Identifiable {
    let id = UUID()
    let row: Int
    let startCol: Int
    let endCol: Int
}

struct UrgentImportantTask: Identifiable {
    let id = UUID()
    let title: String
}

struct CalendarRangeProvider {
    let cal = Calendar.current

    func ranges(from events: [CalendarEvent], in monthDate: Date) -> [CalendarRange] {
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: monthDate)) ?? monthDate
        let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) ?? monthDate

        return events.compactMap { event in
            let rawStart = min(event.start, event.end)
            let rawEnd   = max(event.start, event.end)

            let s = max(rawStart, monthStart)
            let e = min(rawEnd, monthEnd)
            guard s < e else { return nil }

            return CalendarRange(start: s, end: e, color: Color.cyan.opacity(0.70), eventId: event.id)
        }
    }
}

// MARK: - Range Bar Shape

struct RangeBarShape: Shape {
    let isStart: Bool
    let isEnd: Bool
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let tl: CGFloat = isStart ? radius : 0
        let bl: CGFloat = isStart ? radius : 0
        let tr: CGFloat = isEnd ? radius : 0
        let br: CGFloat = isEnd ? radius : 0

        var p = Path()
        p.addRoundedRect(in: rect,
                         topLeftRadius: tl,
                         topRightRadius: tr,
                         bottomLeftRadius: bl,
                         bottomRightRadius: br)
        return p
    }
}

extension Path {
    mutating func addRoundedRect(in rect: CGRect,
                                 topLeftRadius: CGFloat,
                                 topRightRadius: CGFloat,
                                 bottomLeftRadius: CGFloat,
                                 bottomRightRadius: CGFloat) {
        let w = rect.width, h = rect.height
        let x = rect.minX, y = rect.minY

        let tl = min(min(topLeftRadius, h/2), w/2)
        let tr = min(min(topRightRadius, h/2), w/2)
        let bl = min(min(bottomLeftRadius, h/2), w/2)
        let br = min(min(bottomRightRadius, h/2), w/2)

        move(to: CGPoint(x: x + tl, y: y))
        addLine(to: CGPoint(x: x + w - tr, y: y))
        addArc(center: CGPoint(x: x + w - tr, y: y + tr),
               radius: tr,
               startAngle: .degrees(-90),
               endAngle: .degrees(0),
               clockwise: false)

        addLine(to: CGPoint(x: x + w, y: y + h - br))
        addArc(center: CGPoint(x: x + w - br, y: y + h - br),
               radius: br,
               startAngle: .degrees(0),
               endAngle: .degrees(90),
               clockwise: false)

        addLine(to: CGPoint(x: x + bl, y: y + h))
        addArc(center: CGPoint(x: x + bl, y: y + h - bl),
               radius: bl,
               startAngle: .degrees(90),
               endAngle: .degrees(180),
               clockwise: false)

        addLine(to: CGPoint(x: x, y: y + tl))
        addArc(center: CGPoint(x: x + tl, y: y + tl),
               radius: tl,
               startAngle: .degrees(180),
               endAngle: .degrees(270),
               clockwise: false)

        closeSubpath()
    }
}
