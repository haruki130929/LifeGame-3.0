import SwiftUI

struct HomeMainPanelView: View {

    @Binding var selectedTab: TabSelection
    let currentSlot: TimeSlot
    @ObservedObject var slotCardStore: SlotCardConfigStore

    let containerWidth: CGFloat
    let leftTopButtonWidth: CGFloat

    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var customTabStore: CustomTabStore

    @State private var showAddTabSheet = false

    // MARK: - Adaptive Colors
    private var panelColor: Color {
        theme.isDark ? Color(white: 0.14) : Color(.secondarySystemBackground)
    }
    private var panelStroke: Color {
        theme.isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.08)
    }
    private var unselectedTabColor: Color {
        theme.isDark ? Color.white : Color(.tertiarySystemBackground)
    }
    private var unselectedTextColor: Color {
        theme.isDark ? Color.gray.opacity(0.75) : Color(.secondaryLabel)
    }
    private var selectedTextColor: Color {
        theme.isDark ? Color.white.opacity(0.9) : Color(.label)
    }

    // MARK: - Tab Display Models

    private struct TabDisplay: Identifiable, Equatable {
        let id: String
        let selection: TabSelection?   // nil = "+" 按鈕
        let label: String
        let isAddButton: Bool
        let customTab: CustomTab?

        static func tab(_ ct: CustomTab) -> TabDisplay {
            TabDisplay(
                id: ct.id.uuidString,
                selection: .tab(ct.id),
                label: ct.name,
                isAddButton: false,
                customTab: ct
            )
        }

        static let addButton = TabDisplay(
            id: "__add__",
            selection: nil,
            label: "+",
            isAddButton: true,
            customTab: nil
        )
    }

    private var displayTabs: [TabDisplay] {
        var result = customTabStore.tabs.map { TabDisplay.tab($0) }
        result.append(.addButton)
        return result
    }

    var body: some View {
        let allTabs = displayTabs
        let tabCount = allTabs.count
        let tabW = AppLayout.clamp(containerWidth * (AppLayout.isIPad ? 0.14 : 0.19), LayoutTokens.tabWidthMin, LayoutTokens.tabWidthMax)
        let tabH = LayoutTokens.tabHeight(forContainerWidth: containerWidth)
        let overlap = AppLayout.clamp(tabW * 0.12, LayoutTokens.tabOverlapMin, LayoutTokens.tabOverlapMax)

        // 找到當前選中 tab 的 index（"+" 按鈕不算）
        let selectedIndex = allTabs.firstIndex(where: { $0.selection == selectedTab }) ?? 0

        let leadingX = leftTopButtonWidth + LayoutTokens.tabsLeadingGap
        let bumpX = leadingX + CGFloat(selectedIndex) * (tabW - overlap)

        return ZStack(alignment: .topLeading) {

            FolderPanelShape(
                panelCorner: LayoutTokens.panelCorner,
                bumpX: bumpX,
                bumpWidth: tabW,
                bumpHeight: tabH,
                bumpCorner: LayoutTokens.tabCorner,
                bumpSlant: LayoutTokens.tabSlant
            )
            .fill(panelColor)
            .overlay(
                FolderPanelShape(
                    panelCorner: LayoutTokens.panelCorner,
                    bumpX: bumpX,
                    bumpWidth: tabW,
                    bumpHeight: tabH,
                    bumpCorner: LayoutTokens.tabCorner,
                    bumpSlant: LayoutTokens.tabSlant
                )
                .stroke(panelStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(theme.isDark ? 0.25 : 0.10), radius: 18, x: 0, y: 8)

            HomeDashboardContentView(
                selectedTab: selectedTab,
                currentSlot: currentSlot,
                availableWidth: containerWidth,
                slotCardStore: slotCardStore,
                tabHeight: tabH
            )

            // MARK: - Tab Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -overlap) {
                    ForEach(Array(allTabs.enumerated()), id: \.element.id) { index, displayTab in
                        let isSelected = (displayTab.selection == selectedTab) && !displayTab.isAddButton
                        let baseZ = Double(tabCount - index)

                        Button {
                            if displayTab.isAddButton {
                                showAddTabSheet = true
                            } else if let sel = displayTab.selection {
                                withAnimation(DrawerPanel.panelSpring) { selectedTab = sel }
                            }
                        } label: {
                            ZStack {
                                FolderTabShape(cornerRadius: LayoutTokens.tabCorner, slant: LayoutTokens.tabSlant)
                                    .fill(isSelected ? panelColor : unselectedTabColor)
                                    .shadow(
                                        color: .black.opacity(theme.isDark
                                            ? (isSelected ? 0.28 : 0.18)
                                            : (isSelected ? 0.10 : 0.06)),
                                        radius: isSelected ? 10 : 6,
                                        x: 0, y: isSelected ? 4 : 2
                                    )

                                if displayTab.isAddButton {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(unselectedTextColor)
                                } else {
                                    Text(displayTab.label)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(isSelected ? selectedTextColor : unselectedTextColor)
                                        .padding(.horizontal, 14)
                                }
                            }
                            .frame(width: tabW, height: tabH)
                        }
                        .buttonStyle(.plain)
                        .mask(
                            TabOverlapMask(
                                overlap: overlap,
                                cutHeight: tabH * 0.62,
                                slant: LayoutTokens.tabSlant,
                                shouldCut: (!isSelected && index != 0 && !displayTab.isAddButton)
                            )
                        )
                        .zIndex(isSelected ? 10_000 : baseZ)
                    }
                }
                .padding(.leading, leadingX)
            }
            .offset(y: -tabH)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        // MARK: - Sheets
        .sheet(isPresented: $showAddTabSheet) {
            CustomTabEditorSheet(editingTab: nil)
        }
    }
}
