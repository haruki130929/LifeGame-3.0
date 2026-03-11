import SwiftUI

/// 主頁面板內的「內容區」：根據選中的切頁渲染對應卡片
struct HomeDashboardContentView: View {

    let selectedTab: TabSelection
    let currentSlot: TimeSlot

    @EnvironmentObject private var customTabStore: CustomTabStore
    @EnvironmentObject private var timeSlotNameStore: TimeSlotNameStore
    @EnvironmentObject private var theme: ThemeStore

    /// 外框 tabs 的高度（因為內容要往下避開 tab）
    let tabHeight: CGFloat

    // 圓環時段選取狀態（傳給 CardFactory → TomorrowRingCard → TomorrowRingView）
    @State private var ringSelectedID: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 時段標籤（上下間距相等）
                slotLabel
                    .padding(.vertical, 8)
                    .padding(.top, 4)

                if let tab = currentTab {
                    if tab.cardTypes.isEmpty {
                        emptyTabPlaceholder(name: tab.name)
                    } else {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 240), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(tab.cardTypes, id: \.self) { cardType in
                                CardFactory(cardType: cardType, ringSelectedID: $ringSelectedID)
                            }
                        }
                    }
                } else {
                    noTabPlaceholder
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
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
    }

    // MARK: - 時段標籤

    private var slotLabel: some View {
        HStack(spacing: 7) {
            Image(systemName: currentSlot.systemImage)
                .font(.system(size: 16, weight: .bold))
            Text(timeSlotNameStore.displayName(for: currentSlot))
                .font(.system(size: 17, weight: .bold))
        }
        .foregroundStyle(theme.isDark ? .white.opacity(0.7) : .primary.opacity(0.6))
        .padding(.leading, 2)
    }

    // MARK: - Helpers

    private var currentTab: CustomTab? {
        switch selectedTab {
        case .tab(let id):
            return customTabStore.tabs.first { $0.id == id }
        }
    }

    private func emptyTabPlaceholder(name: String) -> some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            Image(systemName: "square.dashed")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("「\(name)」還沒有卡片")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("長按切頁可以編輯內容")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var noTabPlaceholder: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            Image(systemName: "plus.square.dashed")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("點「＋」新增你的第一個切頁")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
