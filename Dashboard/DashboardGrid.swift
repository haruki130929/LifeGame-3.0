import SwiftUI

// 讀取容器寬度用的 PreferenceKey（避免 GeometryReader 破壞 ScrollView 高度計算）
private struct ContainerWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct DashboardGrid<Content: View>: View {
    let items: [CardItem]
    @ViewBuilder let content: (CardItem) -> Content
    
    private let gap: CGFloat = 12
    private let minColumnWidth: CGFloat = 150
    
    @State private var containerWidth: CGFloat = 0
    
    var body: some View {
        let maxColumns = computeMaxColumns(totalWidth: containerWidth)
        let columns: [GridItem] = Array(
            repeating: GridItem(.flexible(), spacing: gap, alignment: .top),
            count: maxColumns
        )
        
        // ✅ Grid 本體不包 GeometryReader，讓它的高度 = 內容高度（ScrollView 才能算對）
        LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
            ForEach(items) { item in
                content(item)
                    .frame(minHeight: item.size.height, alignment: .top)
                    .gridCellColumns(item.size.span(maxColumns: maxColumns))
            }
        }
        // ✅ 用背景的 GeometryReader “只讀寬度”，不影響 Grid 的高度布局
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: ContainerWidthKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(ContainerWidthKey.self) { w in
            // 避免頻繁更新造成抖動
            if abs(containerWidth - w) > 1 {
                containerWidth = w
            }
        }
    }
    
    private func computeMaxColumns(totalWidth: CGFloat) -> Int {
        // 還沒拿到寬度時先給合理預設，避免 0 造成 1 欄怪狀
        guard totalWidth > 0 else { return 3 }
        
        let raw = Int((totalWidth + gap) / (minColumnWidth + gap))
        return max(1, min(raw, 3))
    }
}
