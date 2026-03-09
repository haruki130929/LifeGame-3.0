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
            Section {
                Label(category.rawValue, systemImage: category.systemImage)
                    .font(.headline)
                Text("在這裡選擇細部功能")
                    .foregroundStyle(.secondary)
            }
            
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
            NavigationLink { Text("選緘溝通板（待接上）").navigationTitle("選緘溝通板") } label: {
                Label("選緘溝通板", systemImage: "bubble.left.and.bubble.right")
            }
            
        case .roles:
            NavigationLink { Text("能力五角圖（待接上）").navigationTitle("能力五角圖") } label: {
                Label("能力五角圖", systemImage: "pentagon")
            }
            NavigationLink { Text("角色優勢（待接上）").navigationTitle("角色優勢") } label: {
                Label("角色優勢 / 特性", systemImage: "bolt.heart")
            }
            NavigationLink { Text("裝備系統（待接上）").navigationTitle("裝備系統") } label: {
                Label("裝備系統", systemImage: "backpack")
            }
            
        case .growth:
            NavigationLink { DailyLogHistoryView(store: dailyLogStore) } label: {
                Label("每日紀錄", systemImage: "square.and.pencil")
            }
            NavigationLink { MandalaChartScreen() } label: {
                Label("曼陀羅圖表", systemImage: "square.grid.3x3")
            }
            NavigationLink { Text("近況檢視折線圖（待接上）").navigationTitle("近況檢視") } label: {
                Label("近況檢視（折線圖）", systemImage: "chart.line.uptrend.xyaxis")
            }
            
        case .help:
            NavigationLink { Text("動力筆記（待接上）").navigationTitle("動力筆記") } label: {
                Label("動力筆記", systemImage: "note.text")
            }
            NavigationLink { Text("在意清單（待接上）").navigationTitle("在意清單") } label: {
                Label("在意清單", systemImage: "checklist")
            }
            
        case .diary:
            NavigationLink { DiaryView() } label: {
                Label("日記", systemImage: "book")
            }
            NavigationLink { KyudoNoteListView() } label: {
                Label("弓道筆記", systemImage: "target")
            }
        }
    }
}
