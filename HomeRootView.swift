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
            
            NavigationLink {
                DailyLogHistoryView(store: dailyLogStore)
            } label: {
                Label("每日紀錄", systemImage: "square.and.pencil")
            }
            
            NavigationLink {
                FinanceHubView(wishStore: wishStore, ledgerStore: ledgerStore)
            } label: {
                Label("財務", systemImage: "creditcard")
            }
            
            NavigationLink {
                MandalaChartScreen()
            } label: {
                Label("曼陀羅圖表", systemImage: "square.grid.3x3")
            }
            
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
