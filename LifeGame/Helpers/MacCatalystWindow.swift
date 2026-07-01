import SwiftUI

// Mac Catalyst 專用的視窗美化。
// 在 iPhone / iPad 上全部是 no-op（回傳 self），對現有行為零影響。

#if targetEnvironment(macCatalyst)

extension View {
    /// 把內容限制在最大寬度並水平置中，兩側留白填入背景色，
    /// 避免在寬螢幕的 Mac 視窗上內容被拉得太開、顯得稀疏。
    /// FAB / 水族箱等疊在 HomeRootView 內的元件會跟著這個 frame 一起置中。
    func macCenteredContent(maxWidth: CGFloat = 1366,
                            background: Color = Color(.systemBackground)) -> some View {
        ZStack {
            background
                .ignoresSafeArea()
            self
                .frame(maxWidth: maxWidth, maxHeight: .infinity)
        }
    }

    /// 設定所屬視窗的最小尺寸，避免使用者把 Mac 視窗縮到版面破圖。
    func macWindowMinSize(width: CGFloat, height: CGFloat) -> some View {
        background(MacWindowConfigurator(minSize: CGSize(width: width, height: height)))
    }
}

/// 找到所屬的 UIWindowScene 並設定 `sizeRestrictions.minimumSize`。
private struct MacWindowConfigurator: UIViewRepresentable {
    let minSize: CGSize

    func makeUIView(context: Context) -> ConfiguratorView {
        let view = ConfiguratorView()
        view.minSize = minSize
        return view
    }

    func updateUIView(_ uiView: ConfiguratorView, context: Context) {
        uiView.minSize = minSize
        uiView.applyMinSize()
    }

    final class ConfiguratorView: UIView {
        var minSize: CGSize = .zero

        override func didMoveToWindow() {
            super.didMoveToWindow()
            applyMinSize()
        }

        func applyMinSize() {
            guard let restrictions = window?.windowScene?.sizeRestrictions else { return }
            restrictions.minimumSize = minSize
        }
    }
}

#else

extension View {
    /// 非 Catalyst：no-op。
    @inline(__always)
    func macCenteredContent(maxWidth: CGFloat = 1366,
                            background: Color = .clear) -> some View {
        self
    }

    /// 非 Catalyst：no-op。
    @inline(__always)
    func macWindowMinSize(width: CGFloat, height: CGFloat) -> some View {
        self
    }
}

#endif
