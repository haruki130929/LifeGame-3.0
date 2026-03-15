import SwiftUI

/// 主頁面板內的「內容區」：根據選中的切頁渲染對應卡片
struct HomeDashboardContentView: View {

    let selectedTab: TabSelection
    let currentSlot: TimeSlot

    @EnvironmentObject private var customTabStore: CustomTabStore
    @EnvironmentObject private var timeSlotNameStore: TimeSlotNameStore
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var coachMarkStore: CoachMarkStore

    @ObservedObject var slotCardStore: SlotCardConfigStore

    /// 外框 tabs 的高度（因為內容要往下避開 tab）
    let tabHeight: CGFloat

    // 圓環時段選取狀態（傳給 CardFactory → TomorrowRingCard → TomorrowRingView）
    @State private var ringSelectedID: UUID?

    // iPhone 手風琴：目前展開的卡片（一次一張）
    @State private var expandedCardType: CardType?

    // 編輯切頁卡片
    @State private var showTabEditor = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 時段標籤（上下間距相等）
                slotLabel
                    .padding(.vertical, 8)
                    .padding(.top, 4)

                let slotCards = slotCardStore.items(for: currentSlot).map(\.type)
                    .filter { $0 != .editCards && $0 != .todayStatus && $0 != .quickStart }

                if slotCards.isEmpty {
                    emptySlotPlaceholder
                } else if AppLayout.isIPad {
                    // iPad：卡片 Grid 佈局
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 300), spacing: 16)],
                        spacing: 16
                    ) {
                        ForEach(slotCards, id: \.self) { cardType in
                            CardFactory(cardType: cardType, ringSelectedID: $ringSelectedID)
                        }
                    }
                } else {
                    // iPhone：手風琴文字列
                    VStack(spacing: 12) {
                        ForEach(slotCards.filter { $0.featureID != nil }, id: \.self) { cardType in
                            ExpandableCardRow(
                                cardType: cardType,
                                expandedCardType: $expandedCardType,
                                ringSelectedID: $ringSelectedID
                            )
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppLayout.isIPad ? 20 : 18)
            .padding(.bottom, 16)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                if ringSelectedID != nil {
                    ringSelectedID = nil
                }
            }
        )
        // 切換 Tab 或時段時收起展開的卡片
        .onChange(of: selectedTab) { _, _ in
            expandedCardType = nil
        }
        .onChange(of: currentSlot) { _, _ in
            expandedCardType = nil
        }
    }

    // MARK: - 時段標籤

    private var slotLabel: some View {
        HStack(spacing: 7) {
            Image(systemName: currentSlot.systemImage)
                .font(.system(size: 16, weight: .bold))
            Text(timeSlotNameStore.displayName(for: currentSlot))
                .font(.system(size: 17, weight: .bold))

            Button {
                showTabEditor = true
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(theme.isDark ? .white.opacity(0.35) : .primary.opacity(0.3))
                    .accessibilityLabel("編輯卡片")
            }
            .buttonStyle(.plain)
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        DispatchQueue.main.async {
                            let frame = geo.frame(in: .global)
                            coachMarkStore.reportCenter(
                                CGPoint(x: frame.midX, y: frame.midY),
                                for: .tabEdit
                            )
                        }
                    }
                }
            )
        }
        .foregroundStyle(theme.isDark ? .white.opacity(0.7) : .primary.opacity(0.6))
        .padding(.leading, 2)
        .sheet(isPresented: $showTabEditor) {
            if let tab = currentTab {
                CustomTabEditorSheet(editingTab: tab)
            }
        }
    }

    // MARK: - Helpers

    private var currentTab: CustomTab? {
        switch selectedTab {
        case .tab(let id):
            return customTabStore.tabs.first { $0.id == id }
        }
    }

    private var emptySlotPlaceholder: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            Image(systemName: "square.dashed")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("此時段還沒有卡片")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("點編輯按鈕設定卡片")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
