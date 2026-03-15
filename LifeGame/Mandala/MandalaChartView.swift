import SwiftUI

struct MandalaChartView: View {

    @ObservedObject var store: MandalaStore
    @Binding var isEditMode: Bool
    @FocusState private var focusedCell: String?

    // 編輯模式：拖放
    @State private var dragSource: String? = nil

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
        .overlay(alignment: .top) {
            if isEditMode {
                Text("編輯模式：拖動格子交換位置")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.blue))
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditMode)
    }

    // MARK: - Cell UI

    @ViewBuilder
    private func cellView(row: Int, col: Int) -> some View {

        let style = cellStyle(row: row, col: col)
        let cellId = "\(row)-\(col)"

        if isEditMode {
            // 編輯模式：顯示文字 + 支援拖放交換
            editableDragCell(row: row, col: col, style: style, cellId: cellId)
        } else if let binding = bindingForEditableCell(row: row, col: col) {
            // 正常模式：可編輯格子
            ZStack {
                TextField("", text: binding, axis: .vertical)
                    .lineLimit(3...6)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 13))
                    .focused($focusedCell, equals: cellId)

                if focusedCell != cellId {
                    Text(binding.wrappedValue)
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            ZStack {
                                Color(UIColor.systemGroupedBackground)
                                style.background
                            }
                        )
                        .allowsHitTesting(false)
                }
            }
            .padding(8)
            .frame(minHeight: cellMinHeight)
            .background(style.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style.border, lineWidth: style.borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else if let text = textForReadOnlyCell(row: row, col: col) {
            // 唯讀格子（外圍中心，顯示主題副本）
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(style.foreground)
                .padding(8)
                .frame(maxWidth: .infinity, minHeight: cellMinHeight, alignment: .center)
                .background(style.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(style.border, lineWidth: style.borderWidth)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Color.clear
                .frame(minHeight: cellMinHeight)
        }
    }

    // MARK: - 編輯模式拖放格子

    @ViewBuilder
    private func editableDragCell(row: Int, col: Int, style: CellStyle, cellId: String) -> some View {
        let isEditable = bindingForEditableCell(row: row, col: col) != nil
        let displayText: String = {
            if let binding = bindingForEditableCell(row: row, col: col) {
                return binding.wrappedValue
            }
            if let text = textForReadOnlyCell(row: row, col: col) {
                return text
            }
            return ""
        }()

        Text(displayText)
            .font(.system(size: isGoalCell(row: row, col: col) ? 13 :
                            (textForReadOnlyCell(row: row, col: col) != nil ? 12 : 13),
                          weight: textForReadOnlyCell(row: row, col: col) != nil ? .semibold : .regular))
            .multilineTextAlignment(.center)
            .foregroundStyle(style.foreground)
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: cellMinHeight, alignment: .center)
            .background(style.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(dragSource == cellId ? Color.blue : style.border,
                            lineWidth: dragSource == cellId ? 2 : style.borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(dragSource == cellId ? 0.5 : 1.0)
            .if(isEditable) { view in
                view
                    .draggable(cellId) {
                        Text(displayText)
                            .font(.system(size: 13))
                            .padding(8)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onAppear { dragSource = cellId }
                    }
                    .dropDestination(for: String.self) { items, _ in
                        guard let source = items.first, source != cellId else { return false }
                        let srcParts = source.split(separator: "-").compactMap { Int($0) }
                        let dstParts = cellId.split(separator: "-").compactMap { Int($0) }
                        guard srcParts.count == 2, dstParts.count == 2 else { return false }
                        store.swapCells(from: (srcParts[0], srcParts[1]), to: (dstParts[0], dstParts[1]))
                        dragSource = nil
                        return true
                    } isTargeted: { _ in
                        // 可以加入 hover 效果
                    }
            }
    }

    // MARK: - Mapping (曼陀羅座標對應)

    private let themePositions: [(Int, Int)] = [
        (3, 3), (3, 4), (3, 5),
        (4, 3),         (4, 5),
        (5, 3), (5, 4), (5, 5),
    ]

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
        let blockRow = row / 3
        let blockCol = col / 3
        guard !(blockRow == 1 && blockCol == 1) else { return nil }
        let centerRow = blockRow * 3 + 1
        let centerCol = blockCol * 3 + 1
        guard row == centerRow && col == centerCol else { return nil }
        let themeRow = 3 + blockRow
        let themeCol = 3 + blockCol
        return themeIndexIfThemeCell(row: themeRow, col: themeCol)
    }

    private func actionAddress(row: Int, col: Int) -> (themeIndex: Int, actionIndex: Int)? {
        let blockRow = row / 3
        let blockCol = col / 3
        guard !(blockRow == 1 && blockCol == 1) else { return nil }
        let localRow = row % 3
        let localCol = col % 3
        guard !(localRow == 1 && localCol == 1) else { return nil }
        let themeRow = 3 + blockRow
        let themeCol = 3 + blockCol
        guard let themeIndex = themeIndexIfThemeCell(row: themeRow, col: themeCol) else { return nil }
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
        // 如果有自訂顏色
        if let hex = store.cellColor(row: row, col: col) {
            let color = Color(hex: hex, fallback: .gray)
            let isBlockEdge = (row % 3 == 0) || (col % 3 == 0) || (row % 3 == 2) || (col % 3 == 2)
            let isMajorDivider = row == 3 || row == 6 || col == 3 || col == 6
            return CellStyle(
                background: color,
                border: Color(UIColor.label).opacity(0.3),
                borderWidth: isMajorDivider ? 2 : (isBlockEdge ? 1.2 : 1),
                foreground: Color(UIColor.label)
            )
        }

        let isBlockEdge = (row % 3 == 0) || (col % 3 == 0) || (row % 3 == 2) || (col % 3 == 2)
        let isMajorDivider = row == 3 || row == 6 || col == 3 || col == 6

        if isGoalCell(row: row, col: col) {
            return CellStyle(
                background: Color(UIColor.label).opacity(0.12),
                border: Color(UIColor.label).opacity(0.4),
                borderWidth: isMajorDivider ? 2 : 1.5,
                foreground: Color(UIColor.label)
            )
        }

        if themeIndexIfThemeCell(row: row, col: col) != nil || themeIndexForOuterBlockCenter(row: row, col: col) != nil {
            return CellStyle(
                background: Color(UIColor.label).opacity(0.07),
                border: Color(UIColor.label).opacity(0.3),
                borderWidth: isMajorDivider ? 2 : (isBlockEdge ? 1.2 : 1),
                foreground: Color(UIColor.label)
            )
        }

        return CellStyle(
            background: Color(UIColor.secondarySystemBackground),
            border: Color(UIColor.label).opacity(0.2),
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

// MARK: - Conditional modifier

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Color toHex helper

extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
