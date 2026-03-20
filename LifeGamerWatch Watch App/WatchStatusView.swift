import SwiftUI

struct WatchStatusView: View {
    @EnvironmentObject var dataStore: WatchDataStore

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("今日狀態")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                StatRing(
                    label: "HP",
                    current: dataStore.hp.current,
                    max: dataStore.hp.max,
                    color: .red
                )

                StatRing(
                    label: "FP",
                    current: dataStore.fp.current,
                    max: dataStore.fp.max,
                    color: .orange
                )

                StatRing(
                    label: "MP",
                    current: dataStore.mp.current,
                    max: dataStore.mp.max,
                    color: .blue
                )
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - 單個狀態圓環

private struct StatRing: View {
    let label: String
    let current: Int
    let max: Int
    let color: Color

    private var progress: Double {
        guard max > 0 else { return 0 }
        return Double(current) / Double(max)
    }

    var body: some View {
        HStack(spacing: 10) {
            // 圓環
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 5)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text(label)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }
            .frame(width: 40, height: 40)

            // 數值
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("\(current) / \(max)")
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
