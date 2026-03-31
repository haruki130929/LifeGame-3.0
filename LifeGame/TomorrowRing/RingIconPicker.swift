import SwiftUI

/// 時段圖示選擇器 — 分類顯示，格子排列
struct RingIconPicker: View {
    @Binding var selected: String

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(RingIcons.groups) { group in
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(group.icons, id: \.name) { icon in
                            Button {
                                selected = icon.name
                            } label: {
                                Image(systemName: icon.name)
                                    .font(.system(size: 18))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        selected == icon.name
                                            ? Color.accentColor.opacity(0.2)
                                            : Color(.tertiarySystemFill),
                                        in: RoundedRectangle(cornerRadius: 8)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                selected == icon.name ? Color.accentColor : .clear,
                                                lineWidth: 2
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(icon.label)
                        }
                    }
                }
            }
        }
    }
}
