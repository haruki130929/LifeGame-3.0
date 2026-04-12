import SwiftUI

struct CalendarHubView: View {
    @ObservedObject var store: CalendarStore
    @ObservedObject var settings: CalendarSettingsStore
    @EnvironmentObject private var theme: ThemeStore

    @State private var scope: CalendarScope = .month
    @State private var anchorDate: Date = .now
    @State private var showingAdd: Bool = false
    
    var body: some View {
        let cal = settings.calendar
        
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                
                // 右上角月份標題 + 前後切換
                HStack(spacing: 10) {
                    Button {
                        stepAnchor(-1, calendar: cal)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("上一個月")

                    Spacer()

                    Text(titleText(calendar: cal))
                        .font(.title2).bold()

                    Spacer()

                    Button {
                        stepAnchor(1, calendar: cal)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .accessibilityLabel("下一個月")
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                
                // 主要內容
                Group {
                    switch scope {
                    case .month:
                        MonthScrollView(
                            store: store,
                            calendar: cal,
                            anchorDate: $anchorDate
                        )
                    case .week:
                        WeekTimeGridView(
                            store: store,
                            calendar: cal,
                            anchorDate: $anchorDate
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("行事曆")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) { bottomToolbar }
            
            // 右下角 +（新增事件）
            Button {
                showingAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .frame(width: 56, height: 56)
                    .background(.thinMaterial)
                    .clipShape(Circle())
                    .accessibilityLabel("新增事件")
            }
            .padding(.trailing, 18)
            .padding(.bottom, 18)
        }
        .sheet(isPresented: $showingAdd) {
            NewEventSheet { title, start, end, colorHex, frequency, repeatCount in
                Task {
                    await store.add(title: title, start: start, end: end, colorHex: colorHex, frequency: frequency, repeatCount: repeatCount)
                }
            }
        }
        .navigationTitle("行事曆")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CalendarSettingsView(settings: settings)
                } label: {
                    Image(systemName: "gearshape")
                        .accessibilityLabel("行事曆設定")
                }
            }
        }
        .featureTutorial(.calendar)
    }
    
    private var bottomToolbar: some View {
        HStack(spacing: 12) {
            Button {
                scope = .month
            } label: {
                Label("月", systemImage: "calendar")
            }
            .buttonStyle(.borderedProminent)
            .tint(scope == .month ? theme.accentColor : .gray)
            
            Button {
                scope = .week
            } label: {
                Label("週", systemImage: "rectangle.3.offgrid")
            }
            .buttonStyle(.borderedProminent)
            .tint(scope == .week ? theme.accentColor : .gray)
            
            Spacer()
            
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private func titleText(calendar: Calendar) -> String {
        switch scope {
        case .month:
            return calendar.formatMonthYear(anchorDate)
        case .week:
            // 週模式顯示「M月 yyyy」也可以，保持一致
            return calendar.formatMonthYear(anchorDate)
        }
    }
    
    private func stepAnchor(_ dir: Int, calendar: Calendar) {
        switch scope {
        case .month:
            anchorDate = calendar.date(byAdding: .month, value: dir, to: anchorDate) ?? anchorDate
        case .week:
            anchorDate = calendar.date(byAdding: .day, value: 7 * dir, to: anchorDate) ?? anchorDate
        }
    }
}
