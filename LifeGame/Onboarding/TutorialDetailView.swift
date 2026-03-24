import SwiftUI

struct TutorialDetailView: View {
    let item: TutorialItem
    @EnvironmentObject private var theme: ThemeStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 頂部 icon + 標題
                header
                    .padding(.bottom, 8)

                // 步驟說明
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(item.steps.enumerated()), id: \.offset) { index, step in
                        stepRow(index: index + 1, step: step)
                    }
                }

                // 小技巧提示框
                if let tip = item.tip {
                    tipBox(tip)
                }
            }
            .padding(20)
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            Image(systemName: item.icon)
                .font(.system(size: 36))
                .foregroundStyle(item.color)
                .frame(width: 56, height: 56)
                .background(item.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.title2.bold())

                Text("\(item.steps.count) 個步驟")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Step Row

    private func stepRow(index: Int, step: TutorialStep) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // 步驟編號圓圈
            Text("\(index)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(item.color)
                .clipShape(Circle())

            Text(step.text)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Tip Box

    private func tipBox(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.body)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 4) {
                Text("小技巧")
                    .font(.subheadline.bold())

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.isDark ? Color.yellow.opacity(0.08) : Color.yellow.opacity(0.1))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.yellow.opacity(0.2), lineWidth: 1)
        }
    }
}
