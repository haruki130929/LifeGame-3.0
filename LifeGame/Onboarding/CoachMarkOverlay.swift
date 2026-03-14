import SwiftUI

/// 聚光燈式新手引導覆蓋層
/// 畫面變暗，只有目標元素用圓形高亮（圓圈內是亮的），說明卡片在聚光燈旁邊
///
/// ⚠️ 關鍵設計：
///   GeometryReader 使用 .ignoresSafeArea()，讓 GR origin = 螢幕左上角。
///   所有元素（Path hole、Ring、TipCard）都在同一個「螢幕座標」系統中，
///   避免不同 .ignoresSafeArea() 層級造成座標不對齊。
///   按鈕位置使用 UIKit safe area insets 計算，確保可靠。
struct CoachMarkOverlay: View {
    @EnvironmentObject private var coachStore: CoachMarkStore
    @EnvironmentObject private var theme: ThemeStore

    /// 從 UIKit 取得 safe area insets（可靠，不受 SwiftUI ignoresSafeArea 影響）
    private var windowInsets: UIEdgeInsets {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets ?? .zero
    }

    var body: some View {
        if let mark = coachStore.currentMark {
            GeometryReader { geo in
                let screenSize = geo.size
                let spot = spotlightCenter(for: mark, screenSize: screenSize)
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
            .ignoresSafeArea()   // ← GR 覆蓋全螢幕，所有座標 = 螢幕座標
            .transition(.opacity)
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

    // MARK: - 聚光燈圓心（螢幕座標）
    //
    // 所有按鈕都由各自的 View 用 .frame(in: .global) 回報螢幕座標，
    // 不再用公式計算，避免不同 GR 座標系統不一致。

    private func spotlightCenter(
        for mark: CoachMarkStore.Mark,
        screenSize: CGSize
    ) -> CGPoint {
        // 優先使用按鈕回報的實際螢幕座標
        if let reported = coachStore.buttonCenters[mark] {
            return reported
        }
        // fallback（按鈕尚未回報時的大致位置）
        let insets = windowInsets
        switch mark {
        case .drawerButton:
            return CGPoint(x: 36, y: insets.top + 40)
        case .rightPanel:
            return CGPoint(x: screenSize.width - 36, y: insets.top + 40)
        case .fabButton:
            return CGPoint(x: screenSize.width - 46, y: screenSize.height - 46)
        case .tabEdit:
            return CGPoint(x: 150, y: insets.top + 120)
        }
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

        switch mark {
        case .drawerButton:
            // 左上角 → 卡片在聚光燈正右邊
            return CGPoint(x: spot.x + radius + gap + 120, y: spot.y + 40)

        case .rightPanel:
            // 右上角 → 卡片在聚光燈正左邊
            return CGPoint(x: spot.x - radius - gap - 120, y: spot.y + 40)

        case .fabButton:
            // 右下角 → 卡片在聚光燈左上方
            return CGPoint(x: spot.x - radius - gap - 120, y: spot.y - radius - gap - 60)

        case .tabEdit:
            // tab 區域 → 卡片在下方
            let x = min(spot.x + 80, screenSize.width / 2)
            return CGPoint(x: x, y: spot.y + radius + gap + 80)
        }
    }

    // MARK: - 說明卡片

    @ViewBuilder
    private func tipCard(for mark: CoachMarkStore.Mark) -> some View {
        let info = tipInfo(for: mark)
        let stepIndex = CoachMarkStore.Mark.allCases.firstIndex(of: mark)! + 1
        let total = CoachMarkStore.Mark.allCases.count

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
            return TipInfo(
                icon: "line.3.horizontal",
                title: "功能選單",
                desc: "點這裡打開所有功能分類"
            )
        case .rightPanel:
            return TipInfo(
                icon: "arrow.right.square",
                title: "工具面板",
                desc: "點這裡開啟右側工具面板"
            )
        case .fabButton:
            return TipInfo(
                icon: "plus.circle.fill",
                title: "快速操作",
                desc: "點這裡新增或操作功能"
            )
        case .tabEdit:
            return TipInfo(
                icon: "pencil.circle.fill",
                title: "編輯卡片",
                desc: "點這裡自訂時段顯示的卡片"
            )
        }
    }
}
