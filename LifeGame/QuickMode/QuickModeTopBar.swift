import SwiftUI

/// 簡略模式頂部 — 只顯示進度
struct QuickModeTopBar: View {
    let completedCount: Int
    let totalCount: Int

    @EnvironmentObject private var theme: ThemeStore

    var body: some View {
        HStack(spacing: 8) {
            // 進度條
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))

                    Capsule()
                        .fill(theme.accentColor)
                        .frame(width: geo.size.width * progress)
                        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: completedCount)
                }
            }
            .frame(height: 5)

            Text("\(completedCount)/\(totalCount)")
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var progress: CGFloat {
        guard totalCount > 0 else { return 0 }
        return CGFloat(completedCount) / CGFloat(totalCount)
    }
}
