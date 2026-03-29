import SwiftUI

/// 共用色票選擇器 — 顯示 ColorPalette 中的所有顏色供選擇
struct PaletteColorPicker: View {
    @Binding var selectedHex: String
    var columns: Int = 8

    private let gridItems: [GridItem]

    init(selectedHex: Binding<String>, columns: Int = 8) {
        _selectedHex = selectedHex
        self.columns = columns
        gridItems = Array(repeating: GridItem(.flexible(), spacing: 6), count: columns)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(ColorPalette.allGroups) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: gridItems, spacing: 6) {
                        ForEach(group.colors) { pc in
                            let isSelected = selectedHex.uppercased() == pc.hex.uppercased()
                            Button {
                                selectedHex = pc.hex
                            } label: {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(pc.color)
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                                    )
                                    .overlay(
                                        isSelected
                                            ? Image(systemName: "checkmark")
                                                .font(.caption2.bold())
                                                .foregroundStyle(.white)
                                                .shadow(radius: 2)
                                            : nil
                                    )
                            }
                            .buttonStyle(.plain)
                            .help(pc.name)
                        }
                    }
                }
            }
        }
    }
}

/// 緊湊版色票選擇器 — 小方格密集排列，類似 Word 色盤
struct CompactPaletteColorPicker: View {
    @Binding var selectedHex: String

    private let gridItems = Array(repeating: GridItem(.fixed(20), spacing: 2), count: 25)

    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 2) {
            ForEach(ColorPalette.allColors) { pc in
                let isSelected = selectedHex.uppercased() == pc.hex.uppercased()
                Button {
                    selectedHex = pc.hex
                } label: {
                    Rectangle()
                        .fill(pc.color)
                        .frame(width: 20, height: 20)
                        .border(isSelected ? Color.white : Color.clear, width: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
