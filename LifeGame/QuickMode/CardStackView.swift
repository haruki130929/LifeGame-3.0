import SwiftUI
import CoreMotion
import Combine

/// 卡片堆疊刷掉容器 — 可見後方卡片 + 手機晃動視差效果
struct CardStackView: View {
    let pages: [QuickPage]
    let dailyLogStore: DailyLogStore
    let onTopCardChanged: (QuickPage?) -> Void
    let onProgressChanged: (Int, Int) -> Void

    @EnvironmentObject private var theme: ThemeStore

    @State private var remainingPages: [QuickPage] = []
    @State private var dismissedPages: [QuickPage] = []
    @State private var dragOffset: CGSize = .zero
    @State private var isDraggingHorizontally = false
    @State private var showCompletion = false
    @State private var cardRandomOffsets: [UUID: CardRandomOffset] = [:]
    @State private var undoingCard: QuickPage?

    // 陀螺儀
    @StateObject private var motion = MotionManager()

    private let dismissThreshold: CGFloat = 100

    /// 卡片亂數偏移結構
    struct CardRandomOffset {
        let xOffset: CGFloat
        let yOffset: CGFloat
        let rotation: Double
    }

    var body: some View {
        ZStack {
            if showCompletion {
                completionView
                    .transition(.scale.combined(with: .opacity))
            } else {
                cardStack
            }

            // 左下角返回上一張按鈕
            if !dismissedPages.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Button {
                            undoDismiss()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color(.tertiaryLabel))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                        }
                        .accessibilityLabel("回到上一張卡片")
                        .padding(.leading, 20)
                        .padding(.bottom, 20)
                        Spacer()
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear { resetCards() }
        .onChange(of: pages) { _, newPages in
            resetCards(to: newPages)
        }
    }

    // MARK: - 卡片堆疊（後方卡片可見）

    private var cardStack: some View {
        ZStack {
            ForEach(Array(remainingPages.prefix(3).enumerated().reversed()), id: \.element.id) { index, page in
                let isTop = index == 0

                QuickCardView(
                    page: page,
                    dailyLogStore: dailyLogStore
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 30)
                // 後方卡片亂數交錯（模擬散落感）
                .offset(
                    x: isTop ? 0 : randomOffset(for: page).xOffset,
                    y: isTop ? 0 : randomOffset(for: page).yOffset
                )
                .rotationEffect(isTop ? .zero : .degrees(randomOffset(for: page).rotation))
                .scaleEffect(scale(for: index))
                // 頂部卡片：拖拽偏移
                .offset(isTop ? dragOffset : .zero)
                .rotationEffect(isTop ? dragRotation : .zero)
                // 陀螺儀視差：每張卡片不同幅度，產生深度感
                .offset(
                    x: motion.tilt.width * parallaxAmount(for: index),
                    y: motion.tilt.height * parallaxAmount(for: index)
                )
                .opacity(cardOpacity(for: index))
                .zIndex(Double(remainingPages.count - index))
                .allowsHitTesting(isTop)
                .simultaneousGesture(isTop ? horizontalDragGesture : nil)
                .animation(.spring(response: 0.35, dampingFraction: 0.82), value: dragOffset)
                .animation(.easeOut(duration: 0.15), value: motion.tilt)
            }
        }
    }

    // MARK: - 完成畫面

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(theme.accentColor)

            Text("準備完成！")
                .font(.system(size: 32, weight: .bold))

            Text("所有任務都完成了")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    resetCards()
                }
            } label: {
                Label("重新開始", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(theme.accentColor.opacity(0.12))
                    .foregroundStyle(theme.accentColor)
                    .clipShape(Capsule())
                    .accessibilityLabel("重新開始")
            }
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - 水平拖拽手勢

    private var horizontalDragGesture: some Gesture {
        DragGesture(minimumDistance: 25)
            .onChanged { value in
                if !isDraggingHorizontally {
                    let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                    if isHorizontal {
                        isDraggingHorizontally = true
                    } else {
                        return
                    }
                }

                if isDraggingHorizontally {
                    dragOffset = CGSize(
                        width: value.translation.width,
                        height: value.translation.height * 0.3
                    )
                }
            }
            .onEnded { value in
                defer { isDraggingHorizontally = false }

                guard isDraggingHorizontally else { return }

                if abs(dragOffset.width) > dismissThreshold {
                    dismissTopCard(translation: dragOffset)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    // MARK: - 動畫計算

    private var dragRotation: Angle {
        .degrees(Double(dragOffset.width) / 25)
    }

    /// 每張卡片逐漸縮小（差距很小，後方卡片幾乎同大）
    private func scale(for index: Int) -> CGFloat {
        1.0 - CGFloat(index) * 0.02
    }

    /// 後方卡片逐漸變淡（但仍然清晰可見）
    private func cardOpacity(for index: Int) -> Double {
        switch index {
        case 0: return 1.0
        case 1: return 0.85
        case 2: return 0.65
        default: return 0.45
        }
    }

    /// 陀螺儀視差幅度：越後面的卡片晃動越小（模擬深度）
    private func parallaxAmount(for index: Int) -> CGFloat {
        switch index {
        case 0: return 1.0
        case 1: return 0.6
        case 2: return 0.3
        default: return 0.15
        }
    }

    /// 取得或產生卡片的亂數偏移（模擬散落在桌上的紙張）
    private func randomOffset(for page: QuickPage) -> CardRandomOffset {
        if let existing = cardRandomOffsets[page.id] {
            return existing
        }
        let offset = CardRandomOffset(
            xOffset: CGFloat.random(in: -18...18),
            yOffset: CGFloat.random(in: -12...12),
            rotation: Double.random(in: -10...10)
        )
        DispatchQueue.main.async {
            cardRandomOffsets[page.id] = offset
        }
        return offset
    }

    // MARK: - Actions

    private func dismissTopCard(translation: CGSize) {
        let flyX: CGFloat = translation.width > 0 ? 800 : -800
        let flyY = translation.height * 0.3

        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            dragOffset = CGSize(width: flyX, height: flyY)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                if !remainingPages.isEmpty {
                    let dismissed = remainingPages.removeFirst()
                    dismissedPages.append(dismissed)
                }
                dragOffset = .zero

                let completed = pages.count - remainingPages.count
                onProgressChanged(completed, pages.count)

                if remainingPages.isEmpty {
                    showCompletion = true
                }

                onTopCardChanged(remainingPages.first)
            }
        }
    }

    private func undoDismiss() {
        guard let last = dismissedPages.popLast() else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            showCompletion = false
            undoingCard = last
            remainingPages.insert(last, at: 0)

            let completed = pages.count - remainingPages.count
            onProgressChanged(completed, pages.count)
            onTopCardChanged(remainingPages.first)
        }

        // 清除 undo 動畫狀態
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            undoingCard = nil
        }
    }

    private func resetCards(to newPages: [QuickPage]? = nil) {
        let p = newPages ?? pages
        remainingPages = p
        dismissedPages = []
        dragOffset = .zero
        isDraggingHorizontally = false
        showCompletion = false
        cardRandomOffsets = [:]  // 重新產生亂數
        onTopCardChanged(p.first)
        onProgressChanged(0, p.count)
    }
}

// MARK: - 陀螺儀管理器

@MainActor
private final class MotionManager: ObservableObject {
    @Published var tilt: CGSize = .zero

    private var manager: CMMotionManager?
    private let maxTilt: CGFloat = 28  // 最大偏移像素

    init() {
        let mgr = CMMotionManager()
        guard mgr.isDeviceMotionAvailable else { return }
        self.manager = mgr
        mgr.deviceMotionUpdateInterval = 1.0 / 30  // 30fps
        mgr.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let attitude = motion?.attitude else { return }
            // roll = 左右傾斜, pitch = 前後傾斜
            let x = CGFloat(attitude.roll) * self.maxTilt
            let y = CGFloat(attitude.pitch) * self.maxTilt
            self.tilt = CGSize(width: x, height: y)
        }
    }

    deinit {
        manager?.stopDeviceMotionUpdates()
    }
}
