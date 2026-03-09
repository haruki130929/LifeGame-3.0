import SwiftUI

struct DashboardWidgetGrid: View {
    let types: [CardType]
    let content: (CardType) -> AnyView
    
    init(types: [CardType], @ViewBuilder content: @escaping (CardType) -> some View) {
        self.types = types
        self.content = { AnyView(content($0)) }
    }
    
    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            ForEach(makeRows(), id: \.id) { row in
                GridRow {
                    ForEach(row.items, id: \.self) { type in
                        content(type)
                            .frame(maxWidth: .infinity)
                            .frame(height: type.defaultSize.height)
                            .gridCellColumns(type.defaultSize.span(maxColumns: 2))
                    }
                    
                    // 如果這一列只有一張半寬卡，補一個空格讓排版穩
                    if row.items.count == 1,
                       row.items.first?.defaultSize.span(maxColumns: 2) == 1 {
                        Color.clear
                    }
                }
            }
        }
    }
    
    // 把卡片排成「兩欄」的列：wide/large 單獨一列，small 兩張一列
    private func makeRows() -> [Row] {
        var rows: [Row] = []
        var buffer: [CardType] = []
        
        func flushBuffer() {
            if !buffer.isEmpty {
                rows.append(Row(items: buffer))
                buffer.removeAll()
            }
        }
        
        for t in types {
            if t.defaultSize.span(maxColumns: 2) == 2 {
                flushBuffer()
                rows.append(Row(items: [t]))
            } else {
                buffer.append(t)
                if buffer.count == 2 { flushBuffer() }
            }
        }
        flushBuffer()
        return rows
    }
    
    struct Row: Identifiable {
        let id = UUID()
        let items: [CardType]
    }
}
