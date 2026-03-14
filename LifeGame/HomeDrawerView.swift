import SwiftUI

struct HomeDrawerView: View {
    let currentSlot: TimeSlot
    let onSelectSlot: (TimeSlot) -> Void
    
    let dailyLogStore: DailyLogStore
    let wishStore: WishStore
    let ledgerStore: LedgerStore
    
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var timeSlotNameStore: TimeSlotNameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("一天")
                .font(.headline)
                .padding(.top, 48)

            ForEach(TimeSlot.allCases) { slot in
                Button {
                    onSelectSlot(slot)
                } label: {
                    HStack {
                        Image(systemName: slot.systemImage)
                        Text(timeSlotNameStore.displayName(for: slot))
                        Spacer()
                    }
                    .padding(10)
                    .contentShape(Rectangle())
                    .background(currentSlot == slot ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(Color.clear))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            
            Divider().padding(.vertical, 6)
            
            Text("功能")
                .font(.headline)
            
            categoryLink(.tools,  label: "工具功能", systemImage: "wrench.and.screwdriver")
            categoryLink(.roles,  label: "角色設定", systemImage: "person.crop.circle")
            categoryLink(.growth, label: "自我成長", systemImage: "chart.line.uptrend.xyaxis")
            categoryLink(.help,   label: "困難幫助", systemImage: "lifepreserver")
            categoryLink(.diary,  label: "日記",     systemImage: "book")
            
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
                .contentShape(Rectangle())
            }
            .padding(.bottom, 12)
        }
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }
    
    private func categoryLink(_ category: LGCategory, label: String, systemImage: String) -> some View {
        NavigationLink {
            LGCategoryHubView(
                category: category,
                wishStore: wishStore,
                ledgerStore: ledgerStore,
                dailyLogStore: dailyLogStore,
                closeDrawer: { } // Drawer 關閉由 Host 控制
            )
        } label: {
            HStack {
                Image(systemName: systemImage)
                Text(label)
                Spacer()
            }
            .padding(10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
