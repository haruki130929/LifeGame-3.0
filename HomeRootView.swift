import SwiftUI

struct HomeRootView: View {
    
    // MARK: - Environment
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var calendarSettings: CalendarSettingsStore
    @EnvironmentObject private var fab: FabStore
    
    @EnvironmentObject private var wishStore: WishStore
    @EnvironmentObject private var ledgerStore: LedgerStore
    
    // MARK: - Local Stores
    @StateObject private var slotConfig = SlotCardConfigStore()
    @StateObject private var todoStore = TodoQuadrantStore()
    
    @StateObject private var game = LifeGame()
    @StateObject private var history = HistoryStore()
    @StateObject private var key3Store = Key3Store()
    @StateObject private var moodStore = MoodStore()
    
    // ✅ 重要：不要每次進 DailyLog 都 new 一個
    @StateObject private var dailyLogStore = DailyLogStore()
    
    // MARK: - UI State
    @State private var isDrawerOpen = false
    @State private var currentSlot: TimeSlot = .morning
    @State private var isContentOpen = false
    @State private var tomorrowRing = TomorrowRingPlan.sample
    
    // MARK: - Calendar UI State
    @State private var monthOffset = 0
    private let cal = Calendar.current
    
    private var monthDate: Date {
        cal.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }
    
    private let rangeProvider = CalendarRangeProvider()
    
    // ✅ Drawer/Panel 打開時，底下內容不要吃點擊（避免誤點）
    private var isOverlayPresented: Bool { isDrawerOpen || isContentOpen }
    
    var body: some View {
        ZStack {
            // ✅ 背景只當背景：不吃觸控（修「看不到但擋住」）
            ThemeBackgroundView(style: theme.backgroundStyle) { Color.clear }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            ScrollView {
                VStack(spacing: 12) {
                    headerBar
                    slotContent
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
                .padding(.top, 10)
            }
            .toolbar(.hidden, for: .navigationBar)
            .allowsHitTesting(!isOverlayPresented)
            
            // Drawer mask
            if isDrawerOpen {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { isDrawerOpen = false } }
                    .zIndex(50)
            }
            
            drawerView
                .allowsHitTesting(isDrawerOpen)
                .zIndex(60)
            
            // Right panel
            if isContentOpen {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.spring()) { isContentOpen = false } }
                    .zIndex(200)
                
                ContentPanel(isOpen: $isContentOpen, game: game, mood: moodStore)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .transition(.move(edge: .trailing))
                    .zIndex(210)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            FabButton()
                .padding(.trailing, 16)
                .padding(.bottom, 16)
                .allowsHitTesting(!isOverlayPresented)
        }
        .onAppear { setupFab() }
    }
}

// MARK: - FAB
private extension HomeRootView {
    func setupFab() {
        fab.setActions([
            FabAction(title: "每日紀錄", systemImage: "square.and.pencil") {
                // 你之後要改成真導覽（NavigationPath）再接
                print("FAB: DailyLog")
            },
            FabAction(title: "行事曆", systemImage: "calendar") {
                print("FAB: Calendar")
            },
            FabAction(title: "編輯卡片", systemImage: "slider.horizontal.3") {
                print("FAB: EditCards")
            }
        ])
    }
}

// MARK: - Header
private extension HomeRootView {
    var headerBar: some View {
        HStack(spacing: 10) {
            
            Button {
                withAnimation { isDrawerOpen.toggle() }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .frame(width: 44, height: 44)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Slot content
private extension HomeRootView {
    
    var slotContent: some View {
        let items = slotConfig.items(for: currentSlot)
        return DashboardGrid(items: items) { item in
            cardView(item)
        }
    }
    
    @ViewBuilder
    func cardView(_ item: CardItem) -> some View {
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
private extension HomeRootView {
    
    var drawerView: some View {
        HStack(spacing: 0) {
            if isDrawerOpen {
                drawerContent
                    .transition(.move(edge: .leading))
            }
            Spacer()
        }
    }
    
    var drawerContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("一天")
                .font(.headline)
                .padding(.top, 12)
            
            ForEach(TimeSlot.allCases) { slot in
                Button {
                    currentSlot = slot
                    withAnimation { isDrawerOpen = false }
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
            
            // 👇 放在 ForEach(TimeSlot...) 後面
            Divider().padding(.vertical, 6)
            
            Text("功能")
                .font(.headline)
            
            NavigationLink {
                LGCategoryHubView(
                    category: .tools,
                    wishStore: wishStore,
                    ledgerStore: ledgerStore,
                    dailyLogStore: dailyLogStore,
                    closeDrawer: { withAnimation { isDrawerOpen = false } }
                )
            } label: {
                Label("工具功能", systemImage: "wrench.and.screwdriver")
            }
            .simultaneousGesture(TapGesture().onEnded { withAnimation { isDrawerOpen = false } })
            
            NavigationLink {
                LGCategoryHubView(
                    category: .roles,
                    wishStore: wishStore,
                    ledgerStore: ledgerStore,
                    dailyLogStore: dailyLogStore,
                    closeDrawer: { withAnimation { isDrawerOpen = false } }
                )
            } label: {
                Label("角色設定", systemImage: "person.crop.circle")
            }
            .simultaneousGesture(TapGesture().onEnded { withAnimation { isDrawerOpen = false } })
            
            NavigationLink {
                LGCategoryHubView(
                    category: .growth,
                    wishStore: wishStore,
                    ledgerStore: ledgerStore,
                    dailyLogStore: dailyLogStore,
                    closeDrawer: { withAnimation { isDrawerOpen = false } }
                )
            } label: {
                Label("自我成長", systemImage: "chart.line.uptrend.xyaxis")
            }
            .simultaneousGesture(TapGesture().onEnded { withAnimation { isDrawerOpen = false } })
            
            NavigationLink {
                LGCategoryHubView(
                    category: .help,
                    wishStore: wishStore,
                    ledgerStore: ledgerStore,
                    dailyLogStore: dailyLogStore,
                    closeDrawer: { withAnimation { isDrawerOpen = false } }
                )
            } label: {
                Label("困難幫助", systemImage: "lifepreserver")
            }
            .simultaneousGesture(TapGesture().onEnded { withAnimation { isDrawerOpen = false } })
            
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
        .frame(width: 260)
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }
}

// MARK: - Minimal cards

private struct QuickStartCard: View {
    @ObservedObject var key3Store: Key3Store
    
    var body: some View {
        DashboardCardContainer {
            VStack(alignment: .leading, spacing: 6) {
                Text("快速開始")
                    .font(.headline)
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
                HStack {
                    Text("今日狀態").font(.headline)
                    Spacer()
                }
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
        let width: CGFloat = 420
        
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Content")
                    .font(.title2).bold()
                
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
        .frame(width: width)
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
    
    // 直接把你 HomeRootView 需要用到的依賴傳進來（最省事、最好接）
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
        .onAppear { closeDrawer() } // 進來就把 Drawer 關掉（體感更好）
    }
    
    @ViewBuilder
    private var contentLinks: some View {
        switch category {
        case .tools:
            NavigationLink {
                FinanceHubView(wishStore: wishStore, ledgerStore: ledgerStore)
            } label: {
                Label("財務", systemImage: "creditcard")
            }
            
            NavigationLink {
                Text("選緘溝通板（待接上）")
                    .navigationTitle("選緘溝通板")
            } label: {
                Label("選緘溝通板", systemImage: "bubble.left.and.bubble.right")
            }
            
        case .roles:
            NavigationLink {
                Text("能力五角圖（待接上）")
                    .navigationTitle("能力五角圖")
            } label: {
                Label("能力五角圖", systemImage: "pentagon")
            }
            
            NavigationLink {
                Text("角色優勢（待接上）")
                    .navigationTitle("角色優勢")
            } label: {
                Label("角色優勢 / 特性", systemImage: "bolt.heart")
            }
            
            NavigationLink {
                Text("裝備系統（待接上）")
                    .navigationTitle("裝備系統")
            } label: {
                Label("裝備系統", systemImage: "backpack")
            }
            
        case .growth:
            NavigationLink {
                DailyLogHistoryView(store: dailyLogStore)
            } label: {
                Label("每日紀錄", systemImage: "square.and.pencil")
            }
            
            NavigationLink {
                MandalaChartScreen()
            } label: {
                Label("曼陀羅圖表", systemImage: "square.grid.3x3")
            }
            
            NavigationLink {
                Text("近況檢視折線圖（待接上）")
                    .navigationTitle("近況檢視")
            } label: {
                Label("近況檢視（折線圖）", systemImage: "chart.line.uptrend.xyaxis")
            }
            
        case .help:
            NavigationLink {
                Text("動力筆記（待接上）")
                    .navigationTitle("動力筆記")
            } label: {
                Label("動力筆記", systemImage: "note.text")
            }
            
            NavigationLink {
                Text("在意清單（待接上）")
                    .navigationTitle("在意清單")
            } label: {
                Label("在意清單", systemImage: "checklist")
            }
        }
    }
}
