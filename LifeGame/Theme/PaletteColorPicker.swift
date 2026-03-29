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

/// 緊湊版色票選擇器 — 小方格分頁顯示
struct CompactPaletteColorPicker: View {
    @Binding var selectedHex: String
    @State private var selectedGroup: Int = 0

    private let gridItems = Array(repeating: GridItem(.fixed(22), spacing: 3), count: 10)

    var body: some View {
        let groups = ColorPalette.allGroups

        VStack(spacing: 8) {
            // 分頁標籤
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(groups.enumerated()), id: \.element.id) { idx, group in
                        Button {
                            selectedGroup = idx
                        } label: {
                            Text(group.name)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selectedGroup == idx ? Color.accentColor : Color.secondary.opacity(0.2))
                                .foregroundStyle(selectedGroup == idx ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // 方格
            if selectedGroup < groups.count {
                LazyVGrid(columns: gridItems, spacing: 3) {
                    ForEach(groups[selectedGroup].colors) { pc in
                        let isSelected = selectedHex.uppercased() == pc.hex.uppercased()
                        Button {
                            selectedHex = pc.hex
                        } label: {
                            Rectangle()
                                .fill(pc.color)
                                .frame(width: 22, height: 22)
                                .border(isSelected ? Color.white : Color.clear, width: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
