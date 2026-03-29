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

/// 緊湊版色票選擇器 — 方格排列，按色系分組
struct CompactPaletteColorPicker: View {
    @Binding var selectedHex: String
    var columns: Int = 10

    var body: some View {
        let gridItems = Array(repeating: GridItem(.flexible(), spacing: 4), count: columns)

        VStack(alignment: .leading, spacing: 12) {
            ForEach(ColorPalette.allGroups) { group in
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: gridItems, spacing: 4) {
                        ForEach(group.colors) { pc in
                            let isSelected = selectedHex.uppercased() == pc.hex.uppercased()
                            Button {
                                selectedHex = pc.hex
                            } label: {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(pc.color)
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                                    )
                                    .overlay(
                                        isSelected
                                            ? Image(systemName: "checkmark")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(.white)
                                                .shadow(radius: 2)
                                            : nil
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
