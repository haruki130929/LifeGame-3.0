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
    
    @State private var selectedTab: HomeTab = .tools
    @State private var currentSlot: TimeSlot = .morning
    @State private var showSlotCardEditor = false
    
    @State private var isDrawerOpen = false
    @State private var isContentOpen = false
    private var isOverlayPresented: Bool { isDrawerOpen || isContentOpen }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
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
                moodStore: moodStore
            )
        }
        
        .navigationDestination(isPresented: $showSlotCardEditor) {
            SlotCardEditorView(store: slotCardStore)
        }
    }
}

// MARK: - FAB helpers
private extension HomeContentView {
    var currentFabFeatures: [FeatureID] {
        switch currentSlot {
        case .morning:
            return [.calendar, .diary]
            
        case .afternoon:
            return [.calendar, .ledger]
            
        case .night:
            return [.diary, .wish]
            
        default:
            return [.calendar]
        }
    }
    
    func refreshFabMenu() {
        fab.apply(context: .home(timeSlot: currentSlot, features: currentFabFeatures))
    }
}
