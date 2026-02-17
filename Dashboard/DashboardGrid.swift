import SwiftUI

struct DashboardGrid<Content: View>: View {
    let items: [CardItem]
    @ViewBuilder let content: (CardItem) -> Content
    
    private let gap: CGFloat = 12
    private let minColumnWidth: CGFloat = 150   // 想更寬就調大
    
    var body: some View {
        GeometryReader { geo in
            let maxColumns = computeMaxColumns(totalWidth: geo.size.width)
            
            let columns: [GridItem] = Array(
                repeating: GridItem(.flexible(), spacing: gap),
                count: maxColumns
            )
            
            // ✅ 注意：這裡不再包 ScrollView（外面 HomeRootView 已經有了）
            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                ForEach(items) { item in
                    content(item)
                        .frame(minHeight: item.size.height, alignment: .top)
                        .gridCellColumns(item.size.span(maxColumns: maxColumns))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)   // ✅ 確保吃滿寬度
        }
        .frame(minHeight: 1) // ✅ 避免 GeometryReader 高度變 0
    }
    
    private func computeMaxColumns(totalWidth: CGFloat) -> Int {
        let raw = Int((totalWidth + gap) / (minColumnWidth + gap))
        return max(1, min(raw, 3)) // iPad 最多 3 欄
    }
}
