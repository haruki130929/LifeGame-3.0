import SwiftUI

// MARK: - LGCategory
enum LGCategory: String, CaseIterable, Identifiable {
    case tools = "工具功能"
    case roles = "角色設定"
    case growth = "自我成長"
    case help = "困難幫助"
    case diary = "日記"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .tools: return "wrench.and.screwdriver"
        case .roles: return "person.crop.circle"
        case .growth: return "chart.line.uptrend.xyaxis"
        case .help: return "lifepreserver"
        case .diary: return "book"
        }
    }
}

// MARK: - Hub
struct LGCategoryHubView: View {
    let category: LGCategory
    let wishStore: WishStore
    let ledgerStore: LedgerStore
    let dailyLogStore: DailyLogStore
    let closeDrawer: () -> Void

    var body: some View {
        List {
            Section("功能") {
                contentLinks
            }
        }
        .navigationTitle(category.rawValue)
        .onAppear { closeDrawer() }
    }

    @ViewBuilder private var contentLinks: some View {
        switch category {
        case .tools:
            NavigationLink { FinanceHubView(wishStore: wishStore, ledgerStore: ledgerStore) } label: {
                Label("財務", systemImage: "creditcard")
            }
            NavigationLink { GanttScreen() } label: {
                Label("甘特圖", systemImage: "chart.bar.xaxis")
            }
            NavigationLink { CommunicationBoardView() } label: {
                Label("選緘溝通板", systemImage: "bubble.left.and.bubble.right")
            }

        case .roles:
            comingSoonRow("能力五角圖", systemImage: "pentagon")
            comingSoonRow("角色優勢 / 特性", systemImage: "bolt.heart")
            comingSoonRow("裝備系統", systemImage: "backpack")

        case .growth:
            NavigationLink { DailyLogHistoryView(store: dailyLogStore) } label: {
                Label("每日紀錄", systemImage: "square.and.pencil")
            }
            NavigationLink { MoodThermometerScreen() } label: {
                Label("心情溫度計", systemImage: "heart.text.square")
            }
            NavigationLink { MandalaChartScreen() } label: {
                Label("曼陀羅圖表", systemImage: "square.grid.3x3")
            }
            comingSoonRow("近況檢視（折線圖）", systemImage: "chart.line.uptrend.xyaxis")

        case .help:
            comingSoonRow("動力筆記", systemImage: "note.text")
            comingSoonRow("在意清單", systemImage: "checklist")

        case .diary:
            NavigationLink { DiaryView() } label: {
                Label("日記", systemImage: "book")
            }
            NavigationLink { PracticeDiaryListView() } label: {
                Label("練習日記", systemImage: "pencil.and.list.clipboard")
            }
        }
    }

    /// 尚未實作的功能 — 顯示為灰色不可點擊，帶「即將推出」標籤
    private func comingSoonRow(_ title: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Text("即將推出")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.gray.opacity(0.4))
                .clipShape(Capsule())
        }
        .foregroundStyle(.secondary)
    }
}
