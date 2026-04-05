import SwiftUI

// MARK: - RingItemRowV2

struct RingItemRowV2: View {
    let item: RingItemV2
    var isSelected: Bool = false
    var onTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            Circle()
                .fill(Color(hex: item.colorHex))
                .frame(width: 10, height: 10)

            // Icon
            Image(systemName: item.icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            // Title
            Text(item.title)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            // Time range
            Text("\(RingTimeHelpers.timeString(for: item.startMinute))–\(RingTimeHelpers.timeString(for: item.endMinute))")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)

            // Duration
            Text("\(item.duration)m")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            // Cost indicators
            if item.hpCost > 0 || item.fpCost > 0 {
                HStack(spacing: 4) {
                    if item.hpCost > 0 {
                        Label("\(item.hpCost)", systemImage: "heart")
                            .font(.caption2)
                            .foregroundStyle(.red.opacity(0.7))
                    }
                    if item.fpCost > 0 {
                        Label("\(item.fpCost)", systemImage: "flame")
                            .font(.caption2)
                            .foregroundStyle(.orange.opacity(0.7))
                    }
                }
            }

            // Source badge
            if item.source == .classSchedule {
                Image(systemName: "book.closed")
                    .font(.caption2)
                    .foregroundStyle(.blue.opacity(0.6))
            } else if item.source == .schedule {
                Image(systemName: "calendar.badge.clock")
                    .font(.caption2)
                    .foregroundStyle(.green.opacity(0.6))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}
