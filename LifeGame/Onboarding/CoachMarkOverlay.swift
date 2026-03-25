import SwiftUI

// MARK: - Anchor PreferenceKey

/// 各按鈕用 .anchorPreference 回報自己的中心點
/// SwiftUI 自動轉換座標系，保證準確
struct CoachAnchorKey: PreferenceKey {
    static var defaultValue: [CoachMarkStore.Mark: Anchor<CGPoint>] = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { $1 }
    }
}

// MARK: - 便利修飾器

extension View {
    /// 在按鈕上加上這個修飾器，自動回報位置給 CoachMark 系統
    func coachAnchor(_ mark: CoachMarkStore.Mark) -> some View {
        self.anchorPreference(key: CoachAnchorKey.self, value: .center) { [mark: $0] }
    }
}

// MARK: - CoachMark Overlay

/// 聚光燈式新手引導覆蓋層
/// 使用 Anchor Preference 取得按鈕精確座標，不再依賴 GeometryReader(.global)
struct CoachMarkOverlay: View {
    let anchors: [CoachMarkStore.Mark: Anchor<CGPoint>]
    let proxy: GeometryProxy

    @EnvironmentObject private var coachStore: CoachMarkStore
    @EnvironmentObject private var theme: ThemeStore

    var body: some View {
        if let mark = coachStore.currentMark {
            let screenSize = proxy.size
            let spot = spotlightCenter(for: mark)
            let radius = spotlightRadius(for: mark)
            let fullRect = CGRect(origin: .zero, size: screenSize)

            ZStack {
                // ① 聚光燈遮罩（全螢幕深色 + 圓形鏤空）
                spotlightMask(center: spot, radius: radius, fullRect: fullRect)
                    .fill(Color.black.opacity(0.78), style: FillStyle(eoFill: true))
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            coachStore.next()
                        }
                    }

                // ② 聚光燈光環
                Circle()
                    .strokeBorder(theme.accentColor.opacity(0.8), lineWidth: 3)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(spot)

                // ③ 說明卡片
                tipCard(for: mark)
                    .fixedSize()
                    .position(
                        cardPosition(
                            for: mark,
                            spot: spot,
                            radius: radius,
                            screenSize: screenSize
                        )
                    )
            }
            .animation(.easeInOut(duration: 0.3), value: mark)
        }
    }

    // MARK: - Spotlight 遮罩路徑

    private func spotlightMask(
        center: CGPoint,
        radius: CGFloat,
        fullRect: CGRect
    ) -> Path {
        var path = Path()
        path.addRect(fullRect)
        path.addEllipse(in: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        return path
    }

    // MARK: - 聚光燈圓心（使用 anchor 精確座標）

    private func spotlightCenter(for mark: CoachMarkStore.Mark) -> CGPoint {
        // openDrawer 復用 drawerButton 的位置
        let lookupMark = (mark == .openDrawer) ? .drawerButton : mark

        // 優先使用 anchor 座標（精確）
        if let anchor = anchors[lookupMark] {
            return proxy[anchor]
        }
        // fallback：quickSwipe 沒有對應按鈕，用畫面中央
        let screenSize = proxy.size
        return CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
    }

    // MARK: - 各步驟圓圈半徑

    private func spotlightRadius(for mark: CoachMarkStore.Mark) -> CGFloat {
        switch mark {
        case .drawerButton, .rightPanel:
            return 36
        case .fabButton:
            return 40
        case .tabEdit:
            return 22
        case .openDrawer:
            return 36
        case .tutorialLink:
            return 50
        case .quickSwipe:
            return 80
        case .quickSettings:
            return 36
        }
    }

    // MARK: - 卡片位置（聚光燈旁邊）

    private func cardPosition(
        for mark: CoachMarkStore.Mark,
        spot: CGPoint,
        radius: CGFloat,
        screenSize: CGSize
    ) -> CGPoint {
        let gap: CGFloat = 24
        let cardW: CGFloat = 240
        let cardH: CGFloat = 180
        let margin: CGFloat = 20

        var pt: CGPoint

        switch mark {
        case .drawerButton:
            pt = CGPoint(x: spot.x + radius + gap + cardW / 2, y: spot.y + 40)
        case .rightPanel:
            pt = CGPoint(x: spot.x - radius - gap - cardW / 2, y: spot.y + 40)
        case .fabButton:
            pt = CGPoint(x: spot.x - radius - gap - cardW / 2, y: spot.y - radius - gap - cardH / 2)
        case .tabEdit:
            pt = CGPoint(x: min(spot.x + 80, screenSize.width / 2), y: spot.y + radius + gap + cardH / 2)
        case .openDrawer:
            pt = CGPoint(x: spot.x + radius + gap + cardW / 2, y: spot.y + 40)
        case .tutorialLink:
            pt = CGPoint(x: spot.x + radius + gap + cardW / 2, y: spot.y)
        case .quickSwipe:
            pt = CGPoint(x: screenSize.width / 2, y: spot.y + radius + gap + cardH / 2)
        case .quickSettings:
            pt = CGPoint(x: spot.x - radius - gap - cardW / 2, y: spot.y - radius - gap - cardH / 2)
        }

        // Clamp：確保卡片不超出螢幕
        pt.x = max(margin + cardW / 2, min(pt.x, screenSize.width - margin - cardW / 2))
        pt.y = max(margin + cardH / 2, min(pt.y, screenSize.height - margin - cardH / 2))

        return pt
    }

    // MARK: - 說明卡片

    @ViewBuilder
    private func tipCard(for mark: CoachMarkStore.Mark) -> some View {
        let info = tipInfo(for: mark)
        let sequence = coachStore.activeSequenceForDisplay
        let stepIndex = (sequence.firstIndex(of: mark) ?? 0) + 1
        let total = sequence.count

        VStack(spacing: 14) {
            HStack(spacing: 6) {
                ForEach(0..<total, id: \.self) { i in
                    Capsule()
                        .fill(i < stepIndex
                              ? theme.accentColor
                              : Color.gray.opacity(0.3))
                        .frame(
                            width: i == stepIndex - 1 ? 24 : 8,
                            height: 6
                        )
                }
            }

            Image(systemName: info.icon)
                .font(.system(size: 28))
                .foregroundStyle(theme.accentColor)

            Text(info.title)
                .font(.headline)

            Text(info.desc)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 200)

            HStack(spacing: 20) {
                Button("跳過") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        coachStore.skipAll()
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Button(stepIndex < total ? "下一步" : "完成") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        coachStore.next()
                    }
                }
                .font(.subheadline.bold())
                .foregroundStyle(theme.accentColor)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        }
    }

    // MARK: - 步驟文案

    private struct TipInfo {
        let icon: String
        let title: String
        let desc: String
    }

    private func tipInfo(for mark: CoachMarkStore.Mark) -> TipInfo {
        switch mark {
        case .drawerButton:
            return TipInfo(icon: "line.3.horizontal", title: "功能選單", desc: "點這裡打開所有功能分類")
        case .rightPanel:
            return TipInfo(icon: "arrow.right.square", title: "工具面板", desc: "點這裡開啟右側工具面板")
        case .fabButton:
            return TipInfo(icon: "plus.circle.fill", title: "快速操作", desc: "點這裡新增或操作功能")
        case .tabEdit:
            return TipInfo(icon: "pencil.circle.fill", title: "編輯卡片", desc: "點這裡自訂時段顯示的卡片")
        case .openDrawer:
            return TipInfo(icon: "line.3.horizontal", title: "打開選單", desc: "點擊這裡打開側邊選單")
        case .tutorialLink:
            return TipInfo(icon: "book.fill", title: "使用教學", desc: "這裡有完整的使用教學，隨時可以查看各功能的操作說明")
        case .quickSwipe:
            return TipInfo(icon: "hand.draw", title: "滑動卡片", desc: "左右滑動完成每張任務卡片")
        case .quickSettings:
            return TipInfo(icon: "gearshape.fill", title: "設定", desc: "點這裡開啟設定")
        }
    }
}
