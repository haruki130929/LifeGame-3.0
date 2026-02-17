import SwiftUI

struct MandalaChartView: View {
    
    @ObservedObject var store: MandalaStore
    
    private let gridSize = 9
    private let cellMinHeight: CGFloat = 54
    
    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 90), spacing: 2), count: gridSize), spacing: 2) {
                ForEach(0..<(gridSize * gridSize), id: \.self) { idx in
                    let r = idx / gridSize
                    let c = idx % gridSize
                    
                    cellView(row: r, col: c)
                }
            }
            .padding(12)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Cell UI
    
    @ViewBuilder
    private func cellView(row: Int, col: Int) -> some View {
        
        let style = cellStyle(row: row, col: col)
        
        if let binding = bindingForEditableCell(row: row, col: col) {
            TextField("", text: binding, axis: .vertical)
                .lineLimit(3...6)
                .font(.system(size: 13))
                .padding(8)
                .frame(minHeight: cellMinHeight, alignment: .topLeading)
                .background(style.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(style.border, lineWidth: style.borderWidth)
                )
                .cornerRadius(8)
        } else if let text = textForReadOnlyCell(row: row, col: col) {
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(style.foreground)
                .padding(8)
                .frame(minHeight: cellMinHeight, alignment: .topLeading)
                .background(style.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(style.border, lineWidth: style.borderWidth)
                )
                .cornerRadius(8)
        } else {
            Color.clear
                .frame(minHeight: cellMinHeight)
        }
    }
    
    // MARK: - Mapping (曼陀羅座標對應)
    
    // 中央 3×3 中，8 個主題的位置（row, col）
    private let themePositions: [(Int, Int)] = [
        (3, 3), (3, 4), (3, 5),
        (4, 3),         (4, 5),
        (5, 3), (5, 4), (5, 5),
    ]
    
    // 3×3 區塊中，除中心外的 8 個位置（相對座標）
    private let eightOffsets: [(Int, Int)] = [
        (0, 0), (0, 1), (0, 2),
        (1, 0),         (1, 2),
        (2, 0), (2, 1), (2, 2),
    ]
    
    private func isGoalCell(row: Int, col: Int) -> Bool {
        row == 4 && col == 4
    }
    
    private func themeIndexIfThemeCell(row: Int, col: Int) -> Int? {
        themePositions.firstIndex(where: { $0.0 == row && $0.1 == col })
    }
    
    private func themeIndexForOuterBlockCenter(row: Int, col: Int) -> Int? {
        // 外圍每個 3×3 區塊的中心格 (blockRow*3+1, blockCol*3+1)
        // 但中央區塊 (blockRow=1, blockCol=1) 排除
        let blockRow = row / 3
        let blockCol = col / 3
        guard !(blockRow == 1 && blockCol == 1) else { return nil }
        
        let centerRow = blockRow * 3 + 1
        let centerCol = blockCol * 3 + 1
        guard row == centerRow && col == centerCol else { return nil }
        
        // 對應到 themePositions 的 index：blockRow/blockCol 0..2 映射到主題格在中央 3×3 的位置
        // 主題格的 row = 3 + blockRow, col = 3 + blockCol（排除中心 (4,4)）
        let themeRow = 3 + blockRow
        let themeCol = 3 + blockCol
        return themeIndexIfThemeCell(row: themeRow, col: themeCol)
    }
    
    private func actionAddress(row: Int, col: Int) -> (themeIndex: Int, actionIndex: Int)? {
        let blockRow = row / 3
        let blockCol = col / 3
        guard !(blockRow == 1 && blockCol == 1) else { return nil } // 中央區塊不是 actions
        
        let localRow = row % 3
        let localCol = col % 3
        // 區塊中心格是主題（read-only 顯示），不是 action
        guard !(localRow == 1 && localCol == 1) else { return nil }
        
        // 找到這個外圍區塊對應哪個 theme
        let themeRow = 3 + blockRow
        let themeCol = 3 + blockCol
        guard let themeIndex = themeIndexIfThemeCell(row: themeRow, col: themeCol) else { return nil }
        
        // 對應這個 action 在 8 格裡的 index
        guard let actionIndex = eightOffsets.firstIndex(where: { $0.0 == localRow && $0.1 == localCol }) else {
            return nil
        }
        
        return (themeIndex, actionIndex)
    }
    
    // MARK: - Bindings
    
    private func bindingForEditableCell(row: Int, col: Int) -> Binding<String>? {
        if isGoalCell(row: row, col: col) {
            return Binding(
                get: { store.doc.goal },
                set: { store.doc.goal = $0 }
            )
        }
        
        if let t = themeIndexIfThemeCell(row: row, col: col) {
            return Binding(
                get: { store.doc.themes[safe: t] ?? "" },
                set: { store.doc.themes[t] = $0 }
            )
        }
        
        if let addr = actionAddress(row: row, col: col) {
            return Binding(
                get: { store.doc.actions[safe: addr.themeIndex]?[safe: addr.actionIndex] ?? "" },
                set: { store.doc.actions[addr.themeIndex][addr.actionIndex] = $0 }
            )
        }
        
        return nil
    }
    
    private func textForReadOnlyCell(row: Int, col: Int) -> String? {
        // 外圍區塊中心格：顯示對應主題（重複顯示）
        if let t = themeIndexForOuterBlockCenter(row: row, col: col) {
            return store.doc.themes[safe: t]
        }
        return nil
    }
    
    // MARK: - Styles
    
    private struct CellStyle {
        let background: Color
        let border: Color
        let borderWidth: CGFloat
        let foreground: Color
    }
    
    private func cellStyle(row: Int, col: Int) -> CellStyle {
        // 主線：每個 3×3 區塊的外框用比較深的線
        let isBlockEdge = (row % 3 == 0) || (col % 3 == 0) || (row % 3 == 2) || (col % 3 == 2)
        
        // 更粗的分隔：在 3 和 6 的位置，讓九宮更清楚
        let isMajorDivider = row == 3 || row == 6 || col == 3 || col == 6
        
        if isGoalCell(row: row, col: col) {
            return CellStyle(
                background: Color(UIColor.secondarySystemBackground),
                border: Color(UIColor.label).opacity(0.35),
                borderWidth: isMajorDivider ? 2 : 1,
                foreground: Color(UIColor.label)
            )
        }
        
        if themeIndexIfThemeCell(row: row, col: col) != nil || themeIndexForOuterBlockCenter(row: row, col: col) != nil {
            return CellStyle(
                background: Color(UIColor.tertiarySystemBackground),
                border: Color(UIColor.label).opacity(0.22),
                borderWidth: isMajorDivider ? 2 : (isBlockEdge ? 1.2 : 1),
                foreground: Color(UIColor.label)
            )
        }
        
        return CellStyle(
            background: Color(UIColor.systemBackground),
            border: Color(UIColor.separator),
            borderWidth: isMajorDivider ? 2 : (isBlockEdge ? 1.2 : 1),
            foreground: Color(UIColor.label)
        )
    }
}

// MARK: - Safe index helper

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
