import SwiftUI

struct HomeMainPanelView: View {
    
    @Binding var selectedTab: HomeTab
    
    let containerWidth: CGFloat
    let leftTopButtonWidth: CGFloat
    
    // Colors（放這裡，HomeContentView 就不用管）
    private var panelColor: Color { Color(white: 0.14) }
    private var panelStroke: Color { Color.white.opacity(0.06) }
    private var unselectedTabColor: Color { Color.white }
    private var unselectedTextColor: Color { Color.gray.opacity(0.75) }
    private var selectedTextColor: Color { Color.white.opacity(0.9) }
    
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
            .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 8)
            
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
                                    color: .black.opacity(isSelected ? 0.28 : 0.18),
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
