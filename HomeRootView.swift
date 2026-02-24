import SwiftUI

// MARK: - HomeRootView (Shell)
// 只負責：NavigationStack + 全域疊層（FAB）
// 真正的主畫面內容放在 HomeContentView
struct HomeRootView: View {
    @EnvironmentObject private var fab: FabStore
    
    var body: some View {
        NavigationStack {
            HomeContentView()
        }
        .overlay(alignment: .bottomTrailing) {
            FabButton()
                .padding(.trailing, 16)
                .padding(.bottom, 16)
        }
    }
}

// MARK: - HomeContentView (Main Screen Content)
private struct HomeContentView: View {
    // MARK: Environment
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var calendarSettings: CalendarSettingsStore
    @EnvironmentObject private var fab: FabStore
    @EnvironmentObject private var wishStore: WishStore
    @EnvironmentObject private var ledgerStore: LedgerStore
    
    // MARK: Local Stores
    @StateObject private var slotConfig = SlotCardConfigStore()
    @StateObject private var todoStore = TodoQuadrantStore()
    @StateObject private var game = LifeGame()
    @StateObject private var history = HistoryStore()
    @StateObject private var key3Store = Key3Store()
    @StateObject private var moodStore = MoodStore()
    // ✅ 重要：不要每次進 DailyLog 都 new 一個
    private var dailyLogStore = DailyLogStore()
    
    // MARK: UI State
    @State private var isDrawerOpen = false
    @State private var currentSlot: TimeSlot = .morning
    @State private var isContentOpen = false
    @State private var tomorrowRing = TomorrowRingPlan.sample
    
    // MARK: Calendar UI State
    @State private var monthOffset = 0
    private let cal = Calendar.current
    private let rangeProvider = CalendarRangeProvider()
    private var monthDate: Date {
        cal.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }
    
    // ✅ Drawer/Panel 打開時，底下內容不要吃點擊（避免誤點）
    private var isOverlayPresented: Bool { isDrawerOpen || isContentOpen }
    private let drawerWidth: CGFloat = 260
    private let contentPanelWidth: CGFloat = 420
    
    // MARK: View
    var body: some View {
        ZStack {
            backgroundLayer
            mainScrollContent
        }
        .toolbar(.hidden, for: .navigationBar)
        .allowsHitTesting(!isOverlayPresented)
        
        // Drawer & Panel overlays
        .overlay { drawerMaskLayer }
        .overlay(alignment: .leading) { drawerPanelLayer }
        .overlay { contentMaskLayer }
        .overlay(alignment: .trailing) { contentPanelLayer }
        
        .onAppear { setupFab() }
    }
}

// MARK: - Layers
private extension HomeContentView {
    var backgroundLayer: some View {
        ThemeBackgroundView(style: theme.backgroundStyle) { Color.clear }
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
    
    var mainScrollContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                headerBar
                slotContent
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
            .padding(.top, 10)
        }
    }
}

// MARK: - Drawer & Panel
private extension HomeContentView {
    var drawerMaskLayer: some View {
        Group {
            if isDrawerOpen {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut) { isDrawerOpen = false }
                    }
            }
        }
    }
    
    var drawerPanelLayer: some View {
        drawerContent
            .frame(width: drawerWidth)
            .offset(x: isDrawerOpen ? 0 : -drawerWidth - 20)
            .animation(.easeInOut(duration: 0.22), value: isDrawerOpen)
            .allowsHitTesting(isDrawerOpen)
    }
    
    var contentMaskLayer: some View {
        Group {
            if isContentOpen {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) { isContentOpen = false }
                    }
            }
        }
    }
    
    @ViewBuilder var contentPanelLayer: some View {
        if isContentOpen {
            ContentPanel(isOpen: $isContentOpen, game: game, mood: moodStore)
                .frame(width: contentPanelWidth)
                .transition(.move(edge: .trailing))
                .zIndex(1)
        }
    }
}

// MARK: - FAB Actions
private extension HomeContentView {
    func setupFab() {
        fab.setActions([
            FabAction(title: "每日紀錄", systemImage: "square.and.pencil") { print("FAB: DailyLog") },
            FabAction(title: "行事曆", systemImage: "calendar") { print("FAB: Calendar") },
            FabAction(title: "編輯卡片", systemImage: "slider.horizontal.3") { print("FAB: EditCards") }
        ])
    }
}

// MARK: - Header
private extension HomeContentView {
    var headerBar: some View {
        HStack(spacing: 10) {
            // 左：抽屜
            Button {
                withAnimation(.easeInOut) { isDrawerOpen.toggle() }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .frame(width: 44, height: 44)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            
            // 中：標題
            VStack(alignment: .leading, spacing: 2) {
                Text("現在")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Image(systemName: currentSlot.systemImage)
                    Text(currentSlot.rawValue)
                        .font(.headline)
                }
            }
            
            Spacer()
            
            // ✅ 右：加回「→」按鈕（開右側面板）
            Button {
                withAnimation(.spring()) { isContentOpen = true }
            } label: {
                Image(systemName: "arrow.right")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(isDrawerOpen || isContentOpen)
            .opacity((isDrawerOpen || isContentOpen) ? 0.5 : 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Slot content
private extension HomeContentView {
    var slotContent: some View {
        let items = slotConfig.items(for: currentSlot)
        return DashboardGrid(items: items) { item in
            cardView(item)
        }
    }
    
    @ViewBuilder func cardView(_ item: CardItem) -> some View {
        switch item.type {
        case .quickStart:
            QuickStartCard(key3Store: key3Store)
            
        case .todayStatus:
            TodayStatusCard(game: game, history: history)
            
        case .calendar:
            NavigationLink {
                CalendarScreen()
            } label: {
                CalendarCard(
                    size: item.size,
                    monthDate: monthDate,
                    ranges: rangeProvider.ranges(from: calendarStore.events, in: monthDate),
                    onPrevMonth: { monthOffset -= 1 },
                    onNextMonth: { monthOffset += 1 },
                    urgentImportantTasks: [
                        UrgentImportantTask(title: "明天要交的作業"),
                        UrgentImportantTask(title: "回覆訊息")
                    ]
                )
            }
            .buttonStyle(.plain)
            
        case .dailyLog:
            DashboardCardLink(destination: DailyLogHistoryView(store: dailyLogStore)) {
                DailyLogCard(size: item.size)
            }
            
        case .editCards:
            DashboardCardLink(destination: SlotCardEditorView(store: slotConfig)) {
                EditCardsCard(slot: currentSlot, size: item.size)
            }
            
        case .todoQuadrant:
            TodoQuadrantCardLarge(store: todoStore)
            
        case .tomorrowRing:
            NavigationLink {
                TomorrowRingDetailView(plan: $tomorrowRing)
            } label: {
                TomorrowRingCard(size: item.size, plan: $tomorrowRing)
            }
            .buttonStyle(.plain)
            
        case .bagRequired:
            NavigationLink {
                Bag_BackpackChecklistView()
            } label: {
                BagRequiredCardLarge(size: item.size)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Drawer
private extension HomeContentView {
    var drawerContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("一天")
                .font(.headline)
                .padding(.top, 12)
            
            ForEach(TimeSlot.allCases) { slot in
                Button {
                    currentSlot = slot
                    withAnimation(.easeInOut) { isDrawerOpen = false }
                } label: {
                    HStack {
                        Image(systemName: slot.systemImage)
                        Text(slot.rawValue)
                        Spacer()
                    }
                    .padding(10)
                    .background(currentSlot == slot ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(Color.clear))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            
            Divider().padding(.vertical, 6)
            
            Text("功能")
                .font(.headline)
            
            categoryLink(.tools, label: "工具功能", systemImage: "wrench.and.screwdriver")
            categoryLink(.roles, label: "角色設定", systemImage: "person.crop.circle")
            categoryLink(.growth, label: "自我成長", systemImage: "chart.line.uptrend.xyaxis")
            categoryLink(.help, label: "困難幫助", systemImage: "lifepreserver")
            
            Spacer()
            
            NavigationLink {
                SettingsView()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape")
                    Text("設定")
                    Spacer()
                }
                .foregroundStyle(theme.accentColor)
                .padding(10)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 12)
        }
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }
    
    func categoryLink(_ category: LGCategory, label: String, systemImage: String) -> some View {
        NavigationLink {
            LGCategoryHubView(
                category: category,
                wishStore: wishStore,
                ledgerStore: ledgerStore,
                dailyLogStore: dailyLogStore,
                closeDrawer: { withAnimation(.easeInOut) { isDrawerOpen = false } }
            )
        } label: {
            Label(label, systemImage: systemImage)
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                withAnimation(.easeInOut) { isDrawerOpen = false }
            }
        )
    }
}

// MARK: - Minimal cards
private struct QuickStartCard: View {
    @ObservedObject var key3Store: Key3Store
    
    var body: some View {
        DashboardCardContainer {
            VStack(alignment: .leading, spacing: 6) {
                Text("快速開始").font(.headline)
                Text("今天先選一件事開始")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct TodayStatusCard: View {
    @ObservedObject var game: LifeGame
    @ObservedObject var history: HistoryStore
    
    var body: some View {
        DashboardCardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack { Text("今日狀態").font(.headline); Spacer() }
                HStack { Text("HP"); Spacer(); Text("\(game.hp.current)") }
                HStack { Text("FP"); Spacer(); Text("\(game.fp.current)") }
                HStack { Text("MP"); Spacer(); Text("\(game.mp.current)") }
            }
        }
    }
}

private struct ContentPanel: View {
    @Binding var isOpen: Bool
    @ObservedObject var game: LifeGame
    @ObservedObject var mood: MoodStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Content").font(.title2).bold()
                Spacer()
                Button {
                    withAnimation(.spring()) { isOpen = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            TodayStatusContentCard(game: game)
            MoodThermometerCard(mood: mood)
            
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.trailing, 12)
        .padding(.vertical, 12)
        .shadow(radius: 12)
    }
}

// MARK: - 大分類（加 LG 前綴避免撞名）
enum LGCategory: String, CaseIterable, Identifiable {
    case tools = "工具功能"
    case roles = "角色設定"
    case growth = "自我成長"
    case help = "困難幫助"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .tools: return "wrench.and.screwdriver"
        case .roles: return "person.crop.circle"
        case .growth: return "chart.line.uptrend.xyaxis"
        case .help: return "lifepreserver"
        }
    }
}

// MARK: - 分類首頁：點大分類後進來，再點細項
struct LGCategoryHubView: View {
    let category: LGCategory
    let wishStore: WishStore
    let ledgerStore: LedgerStore
    let dailyLogStore: DailyLogStore
    let closeDrawer: () -> Void
    
    var body: some View {
        List {
            Section {
                Label(category.rawValue, systemImage: category.systemImage)
                    .font(.headline)
                Text("在這裡選擇細部功能")
                    .foregroundStyle(.secondary)
            }
            
            Section("功能") {
                contentLinks
            }
        }
        .navigationTitle(category.rawValue)
        .onAppear { closeDrawer() }
    }
    
    @ViewBuilder private var contentLinks: some View {
        switch category {
        case .tools:
            NavigationLink { FinanceHubView(wishStore: wishStore, ledgerStore: ledgerStore) } label: {
                Label("財務", systemImage: "creditcard")
            }
            NavigationLink { Text("選緘溝通板（待接上）").navigationTitle("選緘溝通板") } label: {
                Label("選緘溝通板", systemImage: "bubble.left.and.bubble.right")
            }
            
        case .roles:
            NavigationLink { Text("能力五角圖（待接上）").navigationTitle("能力五角圖") } label: {
                Label("能力五角圖", systemImage: "pentagon")
            }
            NavigationLink { Text("角色優勢（待接上）").navigationTitle("角色優勢") } label: {
                Label("角色優勢 / 特性", systemImage: "bolt.heart")
            }
            NavigationLink { Text("裝備系統（待接上）").navigationTitle("裝備系統") } label: {
                Label("裝備系統", systemImage: "backpack")
            }
            
        case .growth:
            NavigationLink { DailyLogHistoryView(store: dailyLogStore) } label: {
                Label("每日紀錄", systemImage: "square.and.pencil")
            }
            NavigationLink { MandalaChartScreen() } label: {
                Label("曼陀羅圖表", systemImage: "square.grid.3x3")
            }
            NavigationLink { Text("近況檢視折線圖（待接上）").navigationTitle("近況檢視") } label: {
                Label("近況檢視（折線圖）", systemImage: "chart.line.uptrend.xyaxis")
            }
            
        case .help:
            NavigationLink { Text("動力筆記（待接上）").navigationTitle("動力筆記") } label: {
                Label("動力筆記", systemImage: "note.text")
            }
            NavigationLink { Text("在意清單（待接上）").navigationTitle("在意清單") } label: {
                Label("在意清單", systemImage: "checklist")
            }
        }
    }
}
