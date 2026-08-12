import SwiftUI

// MARK: - 側欄大分類
enum SidebarCategory: String, CaseIterable, Identifiable {
    case periods = "時段"
    case tools = "工具功能"
    case roles = "角色設定"
    case growth = "自我成長"
    case help = "困難幫助"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .periods: return "clock"
        case .tools: return "wrench.and.screwdriver"
        case .roles: return "person.crop.circle"
        case .growth: return "chart.line.uptrend.xyaxis"
        case .help: return "lifepreserver"
        }
    }
    
    var subtitle: String {
        switch self {
        case .periods: return String(localized: "依時段安排與執行")
        case .tools: return String(localized: "溝通、財務等工具")
        case .roles: return String(localized: "能力、特性、裝備系統")
        case .growth: return String(localized: "每日紀錄、回顧與圖表")
        case .help: return String(localized: "動力、在意清單與支援")
        }
    }
}

// MARK: - 分類內的細部功能（先用 placeholder）
struct FeatureItem: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
}

extension SidebarCategory {
    var features: [FeatureItem] {
        switch self {
        case .periods:
            return [
                FeatureItem(title: String(localized: "早上"), systemImage: "sunrise"),
                FeatureItem(title: String(localized: "中午"), systemImage: "sun.max"),
                FeatureItem(title: String(localized: "下午"), systemImage: "sun.haze"),
                FeatureItem(title: String(localized: "晚上"), systemImage: "moon.stars")
            ]
        case .tools:
            return [
                FeatureItem(title: String(localized: "選緘溝通板"), systemImage: "bubble.left.and.bubble.right"),
                FeatureItem(title: String(localized: "財務"), systemImage: "creditcard")
            ]
        case .roles:
            return [
                FeatureItem(title: String(localized: "能力五角圖"), systemImage: "pentagon"),
                FeatureItem(title: String(localized: "角色優勢 / 特性"), systemImage: "bolt.heart"),
                FeatureItem(title: String(localized: "裝備系統"), systemImage: "backpack")
            ]
        case .growth:
            return [
                FeatureItem(title: String(localized: "每日紀錄"), systemImage: "square.and.pencil"),
                FeatureItem(title: String(localized: "曼陀羅圖表"), systemImage: "square.grid.3x3"),
                FeatureItem(title: String(localized: "近況檢視（折線圖）"), systemImage: "chart.line.uptrend.xyaxis")
            ]
        case .help:
            return [
                FeatureItem(title: String(localized: "動力筆記"), systemImage: "note.text"),
                FeatureItem(title: String(localized: "在意清單"), systemImage: "checklist")
            ]
        }
    }
}

// MARK: - 主畫面（側欄大分類 → 分類總覽 → 細部頁）
struct ContentView: View {
    @State private var selection: SidebarCategory? = .periods
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("大分類") {
                    ForEach(SidebarCategory.allCases) { category in
                        NavigationLink(value: category) {
                            Label(category.displayName, systemImage: category.systemImage)
                        }
                    }
                }
            }
            .navigationTitle("LifeGame")
        } detail: {
            if let selection {
                CategoryHomeView(category: selection)
            } else {
                WelcomePlaceholderView()
            }
        }
    }
}

// MARK: - 分類總覽頁（你要的「點大分類後進到功能介面」）
struct CategoryHomeView: View {
    let category: SidebarCategory
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(category.subtitle)
                        .foregroundStyle(.secondary)
                }
                
                Section("功能") {
                    ForEach(category.features) { feature in
                        NavigationLink {
                            FeaturePlaceholderView(
                                categoryTitle: category.displayName,
                                featureTitle: feature.title,
                                systemImage: feature.systemImage
                            )
                        } label: {
                            Label(feature.title, systemImage: feature.systemImage)
                        }
                    }
                }
            }
            .navigationTitle(category.displayName)
        }
    }
}

// MARK: - Placeholder：之後每個功能你再換成真的 View
struct FeaturePlaceholderView: View {
    let categoryTitle: String
    let featureTitle: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            
            Text(featureTitle)
                .font(.title2.bold())
            
            Text("這裡之後換成「\(categoryTitle) → \(featureTitle)」的實際功能畫面。")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(featureTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WelcomePlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("從左側選一個分類開始")
                .font(.title3.bold())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
