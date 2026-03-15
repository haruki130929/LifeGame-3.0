import SwiftUI
import Combine

struct HomeContentView: View {
    
    @ObservedObject var game: LifeGame
    @ObservedObject var moodStore: MoodStore
    @ObservedObject var slotCardStore: SlotCardConfigStore
    let dailyLogStore: DailyLogStore
    
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var wishStore: WishStore
    @EnvironmentObject private var ledgerStore: LedgerStore
    @EnvironmentObject private var fab: FabStore
    @EnvironmentObject private var customTabStore: CustomTabStore
    @EnvironmentObject private var coachMarkStore: CoachMarkStore

    @State private var selectedTab: TabSelection = .tab(UUID())
    @State private var currentSlot: TimeSlot = .beforeLeave
    @State private var showSlotCardEditor = false
    
    @State private var isDrawerOpen = false
    @State private var isContentOpen = false
    @State private var showMoodScreen = false
    private var isOverlayPresented: Bool { isDrawerOpen || isContentOpen }

    /// 主背景色：直接從 ThemeStore 讀取，不靠 @Environment(\.colorScheme)
    private var screenBackground: Color {
        theme.isDark ? .black : Color(.systemBackground)
    }

    var body: some View {
        ZStack {
            screenBackground.ignoresSafeArea()
            
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                
                let safeTop = proxy.safeAreaInsets.top
                let safeBottom = proxy.safeAreaInsets.bottom
                let safeLeading = proxy.safeAreaInsets.leading
                let safeTrailing = proxy.safeAreaInsets.trailing
                
                // iPad：面板兩端對齊浮動按鈕位置
                let sideInset = AppLayout.isIPad
                    ? max(safeLeading, safeTrailing) + LayoutTokens.floatSideGap
                    : AppLayout.clamp(w * 0.03, LayoutTokens.panelSideInsetMin, LayoutTokens.panelSideInsetMax)
                let topButtonsY = safeTop + LayoutTokens.floatTopGap
                let leftTopButtonWidth = LayoutTokens.leftTopButtonReservedWidth
                
                let panelTopReserved =
                safeTop
                + LayoutTokens.floatTopGap
                + LayoutTokens.floatButtonSize
                + LayoutTokens.panelTopClearance
                
                let extraBottom = AppLayout.clamp(h * 0.008, 0, 8)
                let panelBottomReserved = safeBottom + extraBottom
                
                let computedPanelHeight = h - panelTopReserved - panelBottomReserved
                let panelHeight = max(LayoutTokens.panelMinHeight, computedPanelHeight)
                
                ZStack {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: panelTopReserved)
                        
                        HomeMainPanelView(
                            selectedTab: $selectedTab,
                            currentSlot: currentSlot,
                            slotCardStore: slotCardStore,
                            containerWidth: w - sideInset * 2,
                            leftTopButtonWidth: leftTopButtonWidth
                        )
                        .frame(height: panelHeight)
                        .padding(.horizontal, sideInset)
                        .padding(.bottom, panelBottomReserved)
                    }
                    
                    FloatingIconButton(systemName: "line.3.horizontal", size: LayoutTokens.floatButtonSize) {
                        withAnimation(DrawerPanel.panelSpring) {
                            isDrawerOpen.toggle()
                            if isDrawerOpen { isContentOpen = false }
                        }
                    }
                    .opacity(isContentOpen ? 0.5 : 1)
                    .disabled(isContentOpen)
                    .background(coachButtonReporter(.drawerButton))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.top, topButtonsY)
                    .padding(.leading, safeLeading + (leftTopButtonWidth - LayoutTokens.floatButtonSize) / 2)

                    FloatingIconButton(systemName: "arrow.right", size: LayoutTokens.floatButtonSize) {
                        withAnimation(DrawerPanel.panelSpring) {
                            isContentOpen.toggle()
                            if isContentOpen { isDrawerOpen = false }
                        }
                    }
                    .opacity((isDrawerOpen || isContentOpen) ? 0.5 : 1)
                    .disabled(isDrawerOpen || isContentOpen)
                    .background(coachButtonReporter(.rightPanel))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, topButtonsY)
                    .padding(.trailing, safeTrailing + LayoutTokens.floatSideGap)
                }
            }
            .allowsHitTesting(!isOverlayPresented)
            // iPhone 邊緣滑動手勢：右滑開 drawer、左滑開右面板
            .gesture(
                AppLayout.isIPad ? nil : DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        guard !isOverlayPresented else { return }
                        let horizontal = value.translation.width
                        let startX = value.startLocation.x

                        if horizontal > 80 && startX < 50 {
                            // 從左邊緣右滑 → 開 drawer
                            withAnimation(DrawerPanel.panelSpring) {
                                isDrawerOpen = true
                                isContentOpen = false
                            }
                        } else if horizontal < -80 && startX > UIScreen.main.bounds.width - 50 {
                            // 從右邊緣左滑 → 開右面板
                            withAnimation(DrawerPanel.panelSpring) {
                                isContentOpen = true
                                isDrawerOpen = false
                            }
                        }
                    }
            )
        }
        .toolbar(.hidden, for: .navigationBar)
        
        .onAppear {
            // 初始化選中第一個切頁
            if let first = customTabStore.tabs.first {
                selectedTab = .tab(first.id)
            }
            refreshFabMenu()
            checkRingDeductions()
        }
        .onChange(of: currentSlot) { _, _ in
            refreshFabMenu()
        }
        .onChange(of: selectedTab) { _, _ in
            refreshFabMenu()
        }
        .onReceive(customTabStore.$tabs) { _ in
            refreshFabMenu()
        }
        .onChange(of: isContentOpen) { _, open in
            withAnimation(.easeInOut(duration: 0.2)) {
                fab.isHidden = open
            }
            if open { fab.collapse() }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            checkRingDeductions()
        }
        
        .overlay(alignment: .leading) {
            HomeDrawerHost(
                isOpen: $isDrawerOpen,
                onSelectSlot: { slot in
                    currentSlot = slot
                },
                dailyLogStore: dailyLogStore,
                wishStore: wishStore,
                ledgerStore: ledgerStore,
                currentSlot: currentSlot
            )
        }
        
        .overlay(alignment: .trailing) {
            HomeRightPanelHost(
                isOpen: $isContentOpen,
                game: game,
                moodStore: moodStore,
                onNavigateToMood: {
                    withAnimation(DrawerPanel.panelSpring) { isContentOpen = false }
                    // 稍微延遲，等右面板關閉後再導航
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showMoodScreen = true
                    }
                }
            )
        }

        .navigationDestination(isPresented: $showSlotCardEditor) {
            SlotCardEditorView(store: slotCardStore)
        }
        .navigationDestination(isPresented: $showMoodScreen) {
            MoodThermometerScreen()
        }
    }
}

// MARK: - FAB helpers
private extension HomeContentView {
    /// 從目前時段的卡片動態產生可導航的 FeatureID 清單
    var currentFabFeatures: [FeatureID] {
        slotCardStore.items(for: currentSlot)
            .compactMap { $0.type.featureID }
    }

    func refreshFabMenu() {
        fab.apply(context: .home(timeSlot: currentSlot, features: currentFabFeatures))
    }

    /// 載入時間圓環計畫，檢查已結束的時段並扣除 HP/FP
    func checkRingDeductions() {
        guard let plan: TomorrowRingPlan = StorageManager.load(
            TomorrowRingPlan.self, forKey: "tomorrow_ring_plan"
        ) else { return }
        game.applyRingDeductions(plan: plan)
    }

    // MARK: - Coach Mark 按鈕位置回報

    /// 用 .background() 附加在按鈕上，回報按鈕中心的螢幕座標
    /// 使用 DispatchQueue.main.async 確保 layout 完成後再讀取
    private func coachButtonReporter(_ mark: CoachMarkStore.Mark) -> some View {
        GeometryReader { geo in
            Color.clear
                .onAppear {
                    DispatchQueue.main.async {
                        let f = geo.frame(in: .global)
                        coachMarkStore.reportCenter(CGPoint(x: f.midX, y: f.midY), for: mark)
                    }
                }
        }
    }
}
