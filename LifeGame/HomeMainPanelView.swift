import SwiftUI

struct HomeMainPanelView: View {

    @Binding var selectedTab: HomeTab

    let containerWidth: CGFloat
    let leftTopButtonWidth: CGFloat

    @EnvironmentObject private var theme: ThemeStore

    // MARK: - Adaptive Colors（從 ThemeStore.isDark 決定）
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
    
    var body: some View {
        let tabW = Layout.clamp(containerWidth * 0.19, LayoutTokens.tabWidthMin, LayoutTokens.tabWidthMax)
        let tabH = Layout.clamp(containerWidth * 0.075, LayoutTokens.tabHeightMin, LayoutTokens.tabHeightMax)
        let overlap = Layout.clamp(tabW * 0.12, LayoutTokens.tabOverlapMin, LayoutTokens.tabOverlapMax)
        
        let tabs = HomeTab.allCases
        let selectedIndex = tabs.firstIndex(of: selectedTab) ?? 0
        
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
                tabHeight: tabH
            )
            
            HStack(spacing: -overlap) {
                ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                    let isSelected = (tab == selectedTab)
                    let baseZ = Double(tabs.count - index)
                    
                    Button {
                        withAnimation(DrawerPanel.panelSpring) { selectedTab = tab }
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
                            
                            HStack(spacing: 8) {
                                if isSelected {
                                    Image(systemName: iconName(for: tab))
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(selectedTextColor)
                                }
                                
                                Text(tab.rawValue)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(isSelected ? selectedTextColor : unselectedTextColor)
                            }
                            .padding(.horizontal, 14)
                        }
                        .frame(width: tabW, height: tabH)
                    }
                    .buttonStyle(.plain)
                    .mask(
                        TabOverlapMask(
                            overlap: overlap,
                            cutHeight: tabH * 0.62,
                            slant: LayoutTokens.tabSlant,
                            shouldCut: (!isSelected && index != 0)
                        )
                    )
                    .zIndex(isSelected ? 10_000 : baseZ)
                }
            }
            .padding(.leading, leadingX)
            .offset(y: -tabH)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func iconName(for tab: HomeTab) -> String {
        switch tab {
        case .tools:  return "wrench.and.screwdriver.fill"
        case .role:   return "person.fill"
        case .growth: return "chart.line.uptrend.xyaxis"
        case .help:   return "questionmark.circle.fill"
        case .diary:  return "book.fill"
        }
    }
}
