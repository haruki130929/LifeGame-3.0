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
    @EnvironmentObject private var navigator: HomeNavigator

    var body: some View {
        List {
            Section("功能") {
                contentLinks
            }
        }
        .navigationTitle(category.displayName)
    }

    /// 點功能 → 讓該功能頁成為堆疊唯一一層（取代目前的分類頁），
    /// 這樣在功能頁按系統返回鈕會直接回到主頁面，而不是退回這個分類頁。
    @ViewBuilder private var contentLinks: some View {
        switch category {
        case .tools:
            featureLink(.wish, String(localized: "財務"), systemImage: "creditcard")
            featureLink(.ganttChart, String(localized: "甘特圖"), systemImage: "chart.bar.xaxis")
            featureLink(.communicationBoard, String(localized: "選緘溝通板"), systemImage: "bubble.left.and.bubble.right")

        case .roles:
            comingSoonRow(String(localized: "能力五角圖"), systemImage: "pentagon")
            comingSoonRow(String(localized: "角色優勢 / 特性"), systemImage: "bolt.heart")
            comingSoonRow(String(localized: "裝備系統"), systemImage: "backpack")

        case .growth:
            featureLink(.dailyLog, String(localized: "每日紀錄"), systemImage: "square.and.pencil")
            featureLink(.moodThermometer, String(localized: "心情溫度計"), systemImage: "heart.text.square")
            featureLink(.mandala, String(localized: "曼陀羅圖表"), systemImage: "square.grid.3x3")
            comingSoonRow(String(localized: "近況檢視（折線圖）"), systemImage: "chart.line.uptrend.xyaxis")

        case .help:
            featureLink(.copingNotes, String(localized: "動力筆記"), systemImage: "lightbulb.fill")
            comingSoonRow(String(localized: "在意清單"), systemImage: "checklist")

        case .diary:
            featureLink(.diary, String(localized: "日記"), systemImage: "book")
            featureLink(.practiceDiary, String(localized: "練習日記"), systemImage: "pencil.and.list.clipboard")
        }
    }

    /// 功能列：外觀同 NavigationLink（含右側 chevron），但點擊改用 navigator.go(to:)
    private func featureLink(_ feature: FeatureID, _ title: String, systemImage: String) -> some View {
        Button {
            navigator.go(to: feature)
        } label: {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
