import SwiftUI

/// 左側抽屜：遮罩 + 面板（抽離 HomeContentView extensions）
struct HomeDrawerHost: View {
    @Binding var isOpen: Bool
    let onSelectSlot: (TimeSlot) -> Void
    
    // Drawer 內容需要用到的依賴
    @EnvironmentObject private var theme: ThemeStore
    let dailyLogStore: DailyLogStore
    let wishStore: WishStore
    let ledgerStore: LedgerStore
    
    // 目前選到哪個 slot（用來 highlight）
    let currentSlot: TimeSlot
    
    var body: some View {
        ZStack(alignment: .leading) {
            if isOpen {
                Color.black.opacity(DrawerPanel.overlayDimOpacity)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeInOut) { isOpen = false } }
            }
            
            GeometryReader { proxy in
                let w = proxy.size.width
                let drawerW = DrawerPanel.drawerWidth(for: w)
                
                HomeDrawerView(
                    currentSlot: currentSlot,
                    onSelectSlot: { slot in
                        onSelectSlot(slot)
                        withAnimation(.easeInOut) { isOpen = false }
                    },
                    dailyLogStore: dailyLogStore,
                    wishStore: wishStore,
                    ledgerStore: ledgerStore
                )
                .frame(width: drawerW)
                .offset(x: isOpen ? 0 : -drawerW - DrawerPanel.drawerHiddenExtra)
                .animation(.easeInOut(duration: DrawerPanel.drawerAnimDuration), value: isOpen)
                .allowsHitTesting(isOpen)
                .zIndex(50)
            }
            .ignoresSafeArea()
        }
    }
}
