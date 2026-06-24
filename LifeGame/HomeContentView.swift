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
    @EnvironmentObject private var tomorrowRingStore: TomorrowRingStore
    @EnvironmentObject private var updateChecker: AppUpdateChecker
    @EnvironmentObject private var slotTimeStore: TimeSlotTimeStore
    @EnvironmentObject private var navigator: HomeNavigator


    @State private var selectedTab: TabSelection = .tab(UUID())
    @State private var currentSlot: TimeSlot = .current()
    /// 打開 App 時只自動選一次時段，之後不覆蓋使用者手動切換
    @State private var didAutoSelectSlot = false
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
                    
                    FloatingIconButton(systemName: "line.3.horizontal", size: LayoutTokens.floatButtonSize, showBadge: updateChecker.hasUpdate) {
                        withAnimation(DrawerPanel.panelSpring) {
                            isDrawerOpen.toggle()
                            if isDrawerOpen { isContentOpen = false }
                        }
                    }
                    .opacity(isContentOpen ? 0.5 : 1)
                    .disabled(isContentOpen)
                    .coachAnchor(.drawerButton)
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
                    .coachAnchor(.rightPanel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, topButtonsY)
                    .padding(.trailing, sideInset)
                }
            }
            // 把整個內容往左挪一點（右側多留邊距，避免右上角按鈕貼邊）
            .padding(.trailing, 20)
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
            // 打開 App 時自動切到目前時間所屬的時段（只做一次，不覆蓋手動切換）
            if !didAutoSelectSlot {
                currentSlot = slotTimeStore.currentSlot()
                didAutoSelectSlot = true
            }
            // 初始化選中第一個切頁
            if let first = customTabStore.tabs.first {
                selectedTab = .tab(first.id)
            }
            // 回到首頁時，根據面板狀態同步 FAB 可見性（功能頁時不干預）
            if !fab.isOnFeaturePage {
                fab.isHidden = isContentOpen || isDrawerOpen
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
        .onReceive(slotCardStore.$config) { _ in
            refreshFabMenu()
        }
        .onChange(of: isContentOpen) { _, open in
            withAnimation(.easeInOut(duration: 0.2)) {
                fab.isHidden = open || isDrawerOpen
            }
            if open { fab.collapse() }
        }
        .onChange(of: isDrawerOpen) { _, open in
            withAnimation(.easeInOut(duration: 0.2)) {
                fab.isHidden = open || isContentOpen
            }
            if open { fab.collapse() }
        }
        // 聚光燈引導：自動打開抽屜
        .onChange(of: coachMarkStore.currentMark) { _, mark in
            if mark == .openDrawer {
                // openDrawer 步驟：聚光燈指向選單按鈕，按下一步後自動打開抽屜
                // 不需要在這裡開，等使用者點「下一步」時開
            }
            if mark == .tutorialLink && !isDrawerOpen {
                withAnimation(DrawerPanel.panelSpring) {
                    isDrawerOpen = true
                    isContentOpen = false
                }
            }
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
                onSelectCategory: { category in
                    navigator.path.append(category)
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

    /// 載入時間圓環計畫，檢查已結束的時段並扣除 HP/FP (V2)
    func checkRingDeductions() {
        tomorrowRingStore.deductCompletedSegments(game: game)
    }

}
