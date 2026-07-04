import SwiftUI
import UIKit

/// 浮動的任務水族箱面板：收合時是小把手，展開是水缸（魚游動 + 失衡提示 + 新增）。
/// 長按可拖曳到任意位置；預設在右中上角（offset 0）。
struct AquariumPanelView: View {
    @EnvironmentObject private var aquarium: AquariumStore
    @EnvironmentObject private var theme: ThemeStore
    @StateObject private var tank = AquariumTank()

    @State private var showComposer = false
    @State private var composerType: FishType = .social
    @State private var selectedFish: UUID?
    /// 面板展開/收合 —— 本機畫面狀態，放這裡而非 store，避免收合時整個首頁重繪造成卡頓
    @State private var isExpanded = false

    // 拖曳位置（相對於預設右中上；存本機、跨啟動保留、不跨裝置同步）
    @AppStorage("aquarium.offsetX") private var savedX: Double = 0
    @AppStorage("aquarium.offsetY") private var savedY: Double = 0
    @State private var liveDrag: CGSize = .zero
    @State private var isDragging = false
    /// GeometryReader 量到的「版面基準」中心 X（不含 .offset 位移）
    @State private var baseMidX: CGFloat? = nil

    private var panelWidth: CGFloat { AppLayout.isIPad ? 360 : 300 }
    private var tankHeight: CGFloat { AppLayout.isIPad ? 300 : 240 }
    /// 收合把手的概略寬度（用於左半邊往右展開時對齊把手左緣）
    private let handleWidthApprox: CGFloat = 90
    /// 只有 iPad（畫面大）可長按拖曳；iPhone 畫面窄，固定在右上角工具按鈕下方
    private var isDraggable: Bool { AppLayout.isIPad }

    var body: some View {
        // 仿右側面板 HomeRightPanelHost：面板「常駐」，用 .offset 滑進滑出 + easeInOut，
        // 完全不用 .transition（transition 的插入/移除成本與怪癖正是先前收合卡頓的來源）。
        ZStack(alignment: .topTrailing) {
            collapsedHandle
                .opacity(isExpanded ? 0 : 1)          // 展開時隱藏把手，避免面板與把手同時出現
                .allowsHitTesting(!isExpanded)

            expandedPanel
                .offset(x: panelHShift + (isExpanded ? 0 : panelSlideOffX))
                .opacity(isExpanded ? 1 : 0)          // 收合時確實隱藏面板（不管滑多遠都保證不見）
                .allowsHitTesting(isExpanded)
        }
        .animation(.easeInOut(duration: 0.28), value: isExpanded)
        .offset(x: isDraggable ? savedX + liveDrag.width : 0,
                y: isDraggable ? savedY + liveDrag.height : 0)
        .background {
            // 只有可拖曳（iPad）才需要追蹤位置判斷左右；iPhone 略過
            if isDraggable {
                GeometryReader { geo in
                    Color.clear
                        .onChange(of: geo.frame(in: .global).midX, initial: true) { _, m in
                            baseMidX = m
                        }
                }
            }
        }
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .simultaneousGesture(dragGesture)
        .onAppear {
            tank.bounds = CGSize(width: panelWidth, height: tankHeight)
            tank.reconcile(with: aquarium.tasks)
            tank.setVisible(isExpanded)
        }
        .onChange(of: isExpanded) { _, expanded in
            tank.setVisible(expanded)
        }
        .onChange(of: aquarium.tasks) { _, newTasks in
            tank.reconcile(with: newTasks)
        }
        // FAB「打開水缸」的訊號（用通知，不動 store → 不重繪首頁）
        .onReceive(NotificationCenter.default.publisher(for: .aquariumOpenRequested)) { _ in
            setExpanded(true)
        }
    }

    /// 收合時面板滑出的方向與距離：右半往右滑出、左半往左滑出（完全離開畫面）
    private var panelSlideOffX: CGFloat {
        isOnLeftHalf ? -(panelWidth + 48) : (panelWidth + 48)
    }

    /// 面板實際中心是否在螢幕左半。
    /// GeometryReader 量到的是未位移的版面基準（.offset 不改變 frame），
    /// 所以要再加上目前的拖曳位移 savedX + liveDrag 才是真正位置。
    private var isOnLeftHalf: Bool {
        guard isDraggable, let base = baseMidX else { return false }
        return base + CGFloat(savedX) + liveDrag.width < windowSize.width / 2
    }

    /// 面板在左半邊時，往右位移讓左緣約對齊把手左緣（於是往右展開）
    private var panelHShift: CGFloat { isOnLeftHalf ? (panelWidth - handleWidthApprox) : 0 }

    // MARK: - 長按拖曳

    private var dragGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
            .onChanged { value in
                guard isDraggable else { return }
                switch value {
                case .first(true):
                    if !isDragging {
                        withAnimation(.easeOut(duration: 0.15)) { isDragging = true }
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    }
                case .second(true, let drag):
                    if !isDragging { withAnimation(.easeOut(duration: 0.15)) { isDragging = true } }
                    if let drag { liveDrag = drag.translation }
                default:
                    break
                }
            }
            .onEnded { value in
                guard isDraggable else { return }
                if case .second(_, let drag?) = value {
                    savedX += Double(drag.translation.width)
                    savedY += Double(drag.translation.height)
                    clampPosition()
                }
                liveDrag = .zero
                withAnimation(.easeOut(duration: 0.15)) { isDragging = false }
            }
    }

    // MARK: - 收合：小把手

    private var collapsedHandle: some View {
        HStack(spacing: 6) {
            if isOnLeftHalf {
                if !aquarium.tasks.isEmpty {
                    Text("\(aquarium.tasks.count)")
                        .font(.caption.weight(.semibold))
                }
                Image(systemName: "fish")
                Image(systemName: "chevron.right")
                    .font(.caption2)
            } else {
                Image(systemName: "chevron.left")
                    .font(.caption2)
                Image(systemName: "fish")
                if !aquarium.tasks.isEmpty {
                    Text("\(aquarium.tasks.count)")
                        .font(.caption.weight(.semibold))
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(theme.floatingButtonFill, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08)))
        .contentShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
        // 快點展開；長按（≥0.35s）則由 dragGesture 接手拖曳
        .onTapGesture { setExpanded(true) }
    }

    // MARK: - 展開：水缸面板

    private var expandedPanel: some View {
        VStack(spacing: 0) {
            header
            tankView
        }
        .frame(width: panelWidth)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12))
        )
        // 不加陰影：動畫時大半徑陰影每幀重新柵格化，是收合卡頓的來源之一
    }

    private var header: some View {
        HStack(spacing: 10) {
            // 面板在左半邊時，收合鈕移到左側並指向左邊（往它收合的方向）
            if isOnLeftHalf { collapseButton }

            Text("任務水族箱")
                .font(.subheadline.weight(.semibold))

            Spacer()

            Text("\(aquarium.tasks.count) 隻魚")
                .font(.caption)
                .foregroundStyle(.secondary)

            addButton

            if !isOnLeftHalf { collapseButton }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .sheet(isPresented: $showComposer) {
            AquariumComposerView(initialType: composerType)
                .environmentObject(aquarium)
                .environmentObject(theme)
        }
    }

    private var addButton: some View {
        Button {
            composerType = .social
            showComposer = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
        }
        .buttonStyle(.plain)
    }

    private var collapseButton: some View {
        Button { setExpanded(false) } label: {
            Image(systemName: isOnLeftHalf ? "chevron.left" : "chevron.right")
                .font(.headline)
        }
        .buttonStyle(.plain)
    }

    private var tankView: some View {
        ZStack(alignment: .topLeading) {
            AquariumPalette.waterColor(isDark: theme.isDark)

            ForEach(tank.sprites) { sprite in
                FishView(type: sprite.type,
                         color: AquariumPalette.bodyColor(for: sprite.type, isDark: theme.isDark),
                         facingLeft: sprite.facingLeft)
                    .frame(width: 58 * sprite.scale, height: 40 * sprite.scale)
                    .position(sprite.pos)
                    .onTapGesture { selectedFish = sprite.id }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)))
            }

            if let tip = aquarium.imbalanceTip {
                tipBanner(tip)
            }

            if let id = selectedFish, let task = aquarium.task(id) {
                fishCallout(task)
            }
        }
        // 固定尺寸，不用 GeometryReader —— GeometryReader 在 .transition 期間會跟 header 不同步，
        // 收合時水缸瞬間消失、標題卻留在原地淡出（就是「卡卡糊掉」的成因）。尺寸本來就是固定的。
        .frame(width: panelWidth, height: tankHeight)
        .clipped()
    }

    // MARK: - 失衡提示

    private func tipBanner(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(text)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.yellow.opacity(0.92), in: Capsule())
        .foregroundStyle(.black.opacity(0.82))
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    // MARK: - 點魚 → 任務名稱 + 完成

    private func fishCallout(_ task: AquariumTask) -> some View {
        ZStack {
            Color.black.opacity(0.04)
                .contentShape(Rectangle())
                .onTapGesture { selectedFish = nil }

            VStack(spacing: 10) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.center)
                HStack(spacing: 10) {
                    Button("關閉") { selectedFish = nil }
                        .buttonStyle(.bordered)
                    Button {
                        complete(task.id)
                    } label: {
                        Label("完成", systemImage: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func setExpanded(_ expanded: Bool) {
        // 動畫由 body 的 .animation(.easeInOut, value: isExpanded) 驅動；
        // tank 計時器的啟停由 .onChange(of: isExpanded) 管理
        isExpanded = expanded
    }

    private func complete(_ id: UUID) {
        selectedFish = nil
        aquarium.complete(id)
    }

    /// 目前視窗（非整個螢幕，兼顧 iPad 分割/Catalyst）的尺寸
    private var windowSize: CGSize {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
            ?? scenes.flatMap { $0.windows }.first
        return window?.bounds.size ?? UIScreen.main.bounds.size
    }

    /// 夾限拖曳位置，避免整個水族箱被拖出畫面找不回來（base 在右上：往左為負、往下為正）
    private func clampPosition() {
        let s = windowSize
        savedX = min(max(savedX, -(s.width - 120)), 24)
        savedY = min(max(savedY, -120), s.height - 200)
    }
}

extension Notification.Name {
    /// FAB「打開水缸」→ 通知 AquariumPanelView 展開（不經 store，避免首頁重繪）
    static let aquariumOpenRequested = Notification.Name("aquariumOpenRequested")
}
