import SwiftUI

/// iPad 用：卡片網格排版。三種尺寸都佔「一欄」，差別在高度（大最高、直式 → 中 → 小）。
/// 同一列塞滿 maxColumns 張，靠上對齊，每張高度由卡片內容與 minHeight 決定。
///
/// 欄寬直接用「上層面板傳入的 availableWidth」計算，
/// 不再靠 `.background(GeometryReader)` 非同步量測 —— 那種量測在第一次 render
/// 可能回傳 0，導致 `width(for:)` 變成 nil、卡片塌縮成內容最小寬度（行事曆日期被截斷）。
struct SpanCardGrid: View {
    let items: [CardItem]
    /// 可用內容寬度（已扣掉左右 padding，由上層面板同步傳入，保證 > 0）
    let availableWidth: CGFloat
    @Binding var ringSelectedID: UUID?

    private let spacing: CGFloat = 16
    private let minColumnWidth: CGFloat = 300   // 一格 ≈ 原本卡片寬度（與舊版自適應一致）

    var body: some View {
        let maxColumns = maxColumns(for: availableWidth)
        let rows = packRows(items, maxColumns: maxColumns)

        VStack(spacing: spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(row) { item in
                        CardFactory(cardType: item.type, size: item.size, ringSelectedID: $ringSelectedID)
                            .frame(width: width(for: item, maxColumns: maxColumns))
                            .frame(minHeight: item.size.height, alignment: .top)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func maxColumns(for width: CGFloat) -> Int {
        guard width > 0 else { return 2 }
        let n = Int((width + spacing) / (minColumnWidth + spacing))
        return max(2, min(4, n))
    }

    private func width(for item: CardItem, maxColumns: Int) -> CGFloat? {
        guard availableWidth > 0 else { return nil }
        let span = min(item.size.span(maxColumns: maxColumns), maxColumns)
        let colWidth = (availableWidth - spacing * CGFloat(maxColumns - 1)) / CGFloat(maxColumns)
        return colWidth * CGFloat(span) + spacing * CGFloat(span - 1)
    }

    /// 依跨欄數把卡片打包成一列列（一列總跨欄不超過 maxColumns）
    private func packRows(_ items: [CardItem], maxColumns: Int) -> [[CardItem]] {
        var rows: [[CardItem]] = []
        var current: [CardItem] = []
        var used = 0
        for item in items {
            let span = min(item.size.span(maxColumns: maxColumns), maxColumns)
            if used + span > maxColumns, !current.isEmpty {
                rows.append(current)
                current = []
                used = 0
            }
            current.append(item)
            used += span
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }
}
