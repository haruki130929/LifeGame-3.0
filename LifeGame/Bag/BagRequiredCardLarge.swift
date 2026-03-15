import SwiftUI
import SwiftData

/// 主頁用：Large 卡片（只顯示「必帶」）
/// - 點一下圖案：變綠＋打勾（直接改 SwiftData model）
/// - 點右上角：進入「整理書包」頁面
struct BagRequiredCardLarge: View {
    let size: CardSize

    @Query(
        filter: #Predicate<BagItemModel> { $0.isRequired == true },
        sort: \BagItemModel.name
    )
    private var requiredItems: [BagItemModel]

    @Environment(\.modelContext) private var context

    // Large 版用 4 列
    private let cols: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        DashboardCardContainer {
            VStack(alignment: .leading, spacing: 12) {

                // Header
                HStack(spacing: 10) {
                    Image(systemName: "backpack")
                        .font(.headline)

                    Text("整理書包")
                        .font(.headline)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Icons
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(requiredItems) { item in
                        RequiredIconChip(
                            icon: item.icon,
                            name: item.name,
                            isChecked: item.isChecked
                        ) {
                            toggle(item)
                        }
                    }
                }

                // Footer line
                HStack {
                    Text("必帶 \(requiredItems.count) 樣")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Spacer()

                    let done = requiredItems.filter(\.isChecked).count
                    Text("\(done)/\(requiredItems.count)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
    }

    private func toggle(_ item: BagItemModel) {
        item.isChecked.toggle()
        try? context.save()
    }
}

private struct RequiredIconChip: View {
    let icon: String
    let name: String
    let isChecked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isChecked ? .green : .primary)
                        .frame(height: 26)

                    Text(name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, minHeight: 64)
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(isChecked ? 0.14 : 0.06), lineWidth: 1)
                )

                if isChecked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
