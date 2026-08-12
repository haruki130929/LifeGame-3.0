import SwiftUI

struct HomeDrawerView: View {
    let currentSlot: TimeSlot
    let onSelectSlot: (TimeSlot) -> Void
    let onSelectCategory: (LGCategory) -> Void

    let dailyLogStore: DailyLogStore
    let wishStore: WishStore
    let ledgerStore: LedgerStore
    
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var timeSlotNameStore: TimeSlotNameStore
    @EnvironmentObject private var updateChecker: AppUpdateChecker

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("一天")
                .font(.headline)

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
            
            categoryLink(.tools,  label: String(localized: "工具功能"), systemImage: "wrench.and.screwdriver")
            categoryLink(.roles,  label: String(localized: "角色設定"), systemImage: "person.crop.circle")
            categoryLink(.growth, label: String(localized: "自我成長"), systemImage: "chart.line.uptrend.xyaxis")
            categoryLink(.help,   label: String(localized: "困難幫助"), systemImage: "lifepreserver")
            categoryLink(.diary,  label: String(localized: "日記"),     systemImage: "book")
            
            Spacer()

            NavigationLink {
                TutorialView()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "book.fill")
                    Text("使用教學")
                    Spacer()
                }
                .padding(10)
                .foregroundStyle(theme.accentColor)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .coachAnchor(.tutorialLink)

            NavigationLink {
                SettingsView()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape")
                        .overlay(alignment: .topTrailing) {
                            if updateChecker.hasUpdate {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 3, y: -3)
                            }
                        }
                    Text("設定")
                    Spacer()
                }
                .padding(10)
                .foregroundStyle(theme.accentColor)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        }
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }
    
    private func categoryLink(_ category: LGCategory, label: String, systemImage: String) -> some View {
        Button {
            onSelectCategory(category)
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
