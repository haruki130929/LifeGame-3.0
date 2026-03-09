import SwiftUI

struct RingSegment: View {
    let startMinute: Int
    let endMinute: Int
    let color: Color
    let lineWidth: CGFloat
    
    private let totalMinutes = 1440
    
    var body: some View {
        Circle()
            .trim(from: startFraction, to: endFraction)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                )
            )
            .rotationEffect(.degrees(-90))
    }
    
    private var startFraction: CGFloat {
        CGFloat(startMinute) / CGFloat(totalMinutes)
    }
    
    private var endFraction: CGFloat {
        CGFloat(endMinute) / CGFloat(totalMinutes)
    }
}
