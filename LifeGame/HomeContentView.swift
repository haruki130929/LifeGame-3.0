import SwiftUI

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
                
                let sideInset = Layout.clamp(w * 0.03, LayoutTokens.panelSideInsetMin, LayoutTokens.panelSideInsetMax)
                let topButtonsY = safeTop + LayoutTokens.floatTopGap
                let leftTopButtonWidth = LayoutTokens.leftTopButtonReservedWidth
                
                let panelTopReserved =
                safeTop
                + LayoutTokens.floatTopGap
                + LayoutTokens.floatButtonSize
                + LayoutTokens.panelTopClearance
                
                let extraBottom = Layout.clamp(h * 0.008, 0, 8)
                let panelBottomReserved = safeBottom + extraBottom
                
                let computedPanelHeight = h - panelTopReserved - panelBottomReserved
                let panelHeight = max(LayoutTokens.panelMinHeight, computedPanelHeight)
                
                ZStack {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: panelTopReserved)
                        
                        HomeMainPanelView(
                            selectedTab: $selectedTab,
                            currentSlot: currentSlot,
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, topButtonsY)
                    .padding(.trailing, safeTrailing + LayoutTokens.floatSideGap)
                }
            }
            .allowsHitTesting(!isOverlayPresented)
        }
        .toolbar(.hidden, for: .navigationBar)
        
        .onAppear {
            // 初始化選中第一個切頁
            if let first = customTabStore.tabs.first {
                selectedTab = .tab(first.id)
            }
            refreshFabMenu()
        }
        .onChange(of: currentSlot) { _, _ in
            refreshFabMenu()
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
    /// 從 SlotCard 設定動態產生可導航的 FeatureID 清單
    var currentFabFeatures: [FeatureID] {
        slotCardStore.items(for: currentSlot)
            .compactMap { $0.type.featureID }   // 過濾掉 quickStart / todayStatus / editCards
    }

    func refreshFabMenu() {
        fab.apply(context: .home(timeSlot: currentSlot, features: currentFabFeatures))
    }
}
