import SwiftUI

/// 簡略模式頂部導航列
struct QuickModeTopBar: View {
    let currentPage: QuickPage?
    let totalPages: Int
    let currentIndex: Int
    @Binding var showSettings: Bool

    @EnvironmentObject private var theme: ThemeStore

    var body: some View {
        HStack(spacing: 12) {
            // 左：設定按鈕
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            // 中：當前頁面標題
            if let page = currentPage {
                HStack(spacing: 6) {
                    Image(systemName: page.featureType.icon)
                        .font(.system(size: 14))
                    Text(page.featureType.title)
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.primary)
            }

            Spacer()

            // 右：頁面指示器
            HStack(spacing: 5) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 36, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
