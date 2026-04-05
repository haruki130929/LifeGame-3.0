import SwiftUI

/// 設定主題用 — 橫向滾動色票
struct ScrollPaletteColorPicker: View {
    @Binding var selectedHex: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(ColorPalette.allColors) { pc in
                    let isSelected = selectedHex.uppercased() == pc.hex.uppercased()
                    Button {
                        selectedHex = pc.hex
                    } label: {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(pc.color)
                            .frame(width: 28, height: 28)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

/// 緊湊版色票選擇器 — 左右滑動分頁顯示
struct CompactPaletteColorPicker: View {
    @Binding var selectedHex: String
    @EnvironmentObject private var theme: ThemeStore
    @State private var currentPage: Int = 0

    private let cellSize: CGFloat = 28
    private let spacing: CGFloat = 8

    var body: some View {
        let groups = ColorPalette.allGroups

        VStack(spacing: 10) {
            // 分頁 TabView（左右滑動）
            TabView(selection: $currentPage) {
                ForEach(Array(groups.enumerated()), id: \.element.id) { idx, group in
                    colorGrid(for: group)
                        .tag(idx)
                        .padding(.horizontal, 4)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: pageHeight(for: groups))

            // 分頁指示器：顯示當前群組名稱和圓點
            VStack(spacing: 6) {
                Text(groups.indices.contains(currentPage) ? groups[currentPage].name : "")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    ForEach(Array(groups.enumerated()), id: \.element.id) { idx, _ in
                        Circle()
                            .fill(idx == currentPage ? theme.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
    }

    // MARK: - Color Grid (per page)

    @ViewBuilder
    private func colorGrid(for group: ColorPalette.ColorGroup) -> some View {
        let columns = Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: 8)

        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(group.colors) { pc in
                    colorCell(pc)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func colorCell(_ pc: ColorPalette.PaletteColor) -> some View {
        let isSelected = selectedHex.uppercased() == pc.hex.uppercased()

        Button {
            selectedHex = pc.hex
        } label: {
            Circle()
                .fill(pc.color)
                .frame(width: cellSize, height: cellSize)
                .overlay(
                    Circle()
                        .stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2.5)
                        .padding(-3)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Page height

    /// Compute a reasonable fixed height based on the largest group.
    private func pageHeight(for groups: [ColorPalette.ColorGroup]) -> CGFloat {
        let maxCount = groups.map(\.colors.count).max() ?? 0
        let columns = 8
        let rows = Int(ceil(Double(maxCount) / Double(columns)))
        let displayedRows = min(rows, 5)  // cap at 5 rows, rest scrollable
        return CGFloat(displayedRows) * (cellSize + spacing) + 16
    }
}
