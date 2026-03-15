import SwiftUI
import SwiftData

/// iPhone 手風琴列：同一個外框內，點擊 header 往下展開功能內容
struct ExpandableCardRow: View {
    let cardType: CardType
    @Binding var expandedCardType: CardType?
    @Binding var ringSelectedID: UUID?

    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var game: LifeGame
    @EnvironmentObject private var calendarStore: CalendarStore

    // 時間圓環
    @State private var tomorrowPlan: TomorrowRingPlan = {
        if let saved: TomorrowRingPlan = StorageManager.load(
            TomorrowRingPlan.self, forKey: "tomorrow_ring_plan"
        ) { return saved }
        return .sample
    }()

    // 待辦四象限
    @StateObject private var todoStore = TodoQuadrantStore()

    // 行事曆
    @State private var monthOffset = 0
    private let cal = Calendar.current
    private let rangeProvider = CalendarRangeProvider()
    private var monthDate: Date {
        cal.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }

    private var isExpanded: Bool {
        expandedCardType == cardType
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        VStack(spacing: 0) {
            // MARK: - Header（始終可見）
            headerRow

            // MARK: - 展開內容（同一個框內，直接顯示功能內容）
            if isExpanded {
                Divider()
                    .padding(.top, 8)

                NavigationLink(value: cardType.featureID!) {
                    expandedContent
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if theme.isDark {
                shape.fill(.thinMaterial)
            } else {
                shape.fill(Color.white)
            }
        }
        .clipShape(shape)
        .overlay(
            shape.strokeBorder(
                theme.isDark
                    ? Color.white.opacity(0.06)
                    : Color.black.opacity(0.10),
                lineWidth: 1
            )
        )
        .shadow(
            color: theme.isDark ? .black.opacity(0.3) : .black.opacity(0.08),
            radius: theme.isDark ? 10 : 8,
            x: 0,
            y: theme.isDark ? 6 : 3
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                if isExpanded {
                    expandedCardType = nil
                } else {
                    expandedCardType = cardType
                }
            }
        }
        // 上下滑動：下拉展開、上推收起
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let vertical = value.translation.height
                    guard abs(value.translation.width) < abs(vertical) else { return }

                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        if vertical > 40 && !isExpanded {
                            expandedCardType = cardType
                        } else if vertical < -40 && isExpanded {
                            expandedCardType = nil
                        }
                    }
                }
        )
    }

    // MARK: - Header Row
    private var headerRow: some View {
        HStack(spacing: 12) {
            Image(systemName: cardType.icon)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(cardType.title)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(isExpanded ? -180 : 0))
                .animation(
                    .spring(response: 0.35, dampingFraction: 0.82),
                    value: isExpanded
                )
        }
    }

    // MARK: - 展開的原始內容（不含 DashboardCardContainer / CardHeader）

    @ViewBuilder
    private var expandedContent: some View {
        switch cardType {
        case .tomorrowRing:
            TomorrowRingView(
                plan: $tomorrowPlan,
                selectedItemID: $ringSelectedID,
                gameHP: game.hp,
                gameFP: game.fp
            )
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .onChange(of: tomorrowPlan) { _, newPlan in
                StorageManager.save(newPlan, forKey: "tomorrow_ring_plan")
            }

        case .calendar:
            calendarContent

        case .todoQuadrant:
            todoContent

        case .dailyLog:
            VStack(alignment: .leading, spacing: 8) {
                Text("快速記錄今天")
                    .foregroundStyle(.secondary)
            }

        case .bagRequired:
            bagContent

        case .monthlyScoreCalendar:
            MonthlyScoreInlineContent()

        default:
            EmptyView()
        }
    }

    // MARK: - 行事曆原始內容
    private var calendarContent: some View {
        CalendarCard(
            size: .medium,
            monthDate: monthDate,
            ranges: rangeProvider.ranges(from: calendarStore.events, in: monthDate),
            onPrevMonth: { monthOffset -= 1 },
            onNextMonth: { monthOffset += 1 },
            urgentImportantTasks: todoStore.items(in: .importantUrgent)
                .filter { !$0.isDone }
                .map { UrgentImportantTask(title: $0.title) }
        )
        // 移除 CalendarCard 自帶的背景/陰影（因為已在外框內）
        .shadow(color: .clear, radius: 0)
    }

    // MARK: - 待辦四象限原始內容
    private var todoContent: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                todoQuadrantCell(.importantNotUrgent, "重要不緊急", Color.blue.opacity(0.15))
                todoQuadrantCell(.importantUrgent, "重要又緊急", Color.red.opacity(0.15))
            }
            HStack(spacing: 8) {
                todoQuadrantCell(.notImportantNotUrgent, "不重要不緊急", Color.gray.opacity(0.10))
                todoQuadrantCell(.urgentNotImportant, "緊急不重要", Color.orange.opacity(0.15))
            }
        }
    }

    private func todoQuadrantCell(_ quadrant: TodoQuadrant, _ title: String, _ bg: Color) -> some View {
        let items = todoStore.items(in: quadrant).filter { !$0.isDone }
        return VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            if items.isEmpty {
                Text("—")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(items.prefix(2)) { item in
                    Text("• \(item.title)")
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - 整理書包原始內容
    private var bagContent: some View {
        BagRequiredInlineContent()
    }
}

// MARK: - 整理書包 inline（不含 DashboardCardContainer）

private struct BagRequiredInlineContent: View {
    @Query(
        filter: #Predicate<BagItemModel> { $0.isRequired == true },
        sort: \BagItemModel.name
    )
    private var requiredItems: [BagItemModel]
    @Environment(\.modelContext) private var context

    private let cols: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(requiredItems) { item in
                    BagInlineChip(
                        icon: item.icon,
                        name: item.name,
                        isChecked: item.isChecked
                    ) {
                        item.isChecked.toggle()
                        try? context.save()
                    }
                }
            }

            HStack {
                Text("必帶 \(requiredItems.count) 樣")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                let done = requiredItems.filter(\.isChecked).count
                Text("\(done)/\(requiredItems.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

private struct BagInlineChip: View {
    let icon: String
    let name: String
    let isChecked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isChecked ? .green : .primary)
                        .frame(height: 26)
                    Text(name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, minHeight: 64)
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                if isChecked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 本月結算 inline（不含 DashboardCardShell）

private struct MonthlyScoreInlineContent: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @State private var monthOffset = 0

    private let cal = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 月份導航
            HStack {
                Text(yearMonthString)
                    .font(.headline)
                Spacer()
                Button { monthOffset -= 1 } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                Button { monthOffset += 1 } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
            }

            // 星期列 + 日期格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(cal.chineseWeekdaySymbols, id: \.self) { w in
                    Text(w)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(cells) { cell in
                    if let date = cell.date {
                        let record = historyStore.record(for: date)
                        ZStack {
                            if let r = record {
                                Circle()
                                    .fill(r.difficulty.color)
                                    .frame(width: 22, height: 22)
                            }
                            Text("\(cal.component(.day, from: date))")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(
                                    record != nil ? .white : (cal.isDateInToday(date) ? .accentColor : .primary)
                                )
                        }
                        .frame(height: 28)
                    } else {
                        Color.clear.frame(height: 28)
                    }
                }
            }
        }
    }

    private var selectedMonth: Date {
        cal.date(byAdding: .month, value: monthOffset,
                 to: cal.date(from: cal.dateComponents([.year, .month], from: Date()))!) ?? Date()
    }

    private var yearMonthString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.dateFormat = "yyyy年 M月"
        return f.string(from: selectedMonth)
    }

    private var cells: [MSInlineCell] {
        let first = selectedMonth
        let days = cal.range(of: .day, in: .month, for: first)?.count ?? 30
        let leading = (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7

        var result: [MSInlineCell] = []
        for _ in 0..<leading { result.append(MSInlineCell(date: nil)) }
        for day in 1...days {
            let d = cal.date(from: DateComponents(
                year: cal.component(.year, from: first),
                month: cal.component(.month, from: first),
                day: day
            ))!
            result.append(MSInlineCell(date: d))
        }
        while result.count % 7 != 0 { result.append(MSInlineCell(date: nil)) }
        return result
    }
}

private struct MSInlineCell: Identifiable {
    let id = UUID()
    let date: Date?
}
