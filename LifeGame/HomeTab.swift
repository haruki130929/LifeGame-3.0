import Foundation

// ✅ 共用的分頁 enum：讓 HomeContentView / HomeDashboardContentView 都能用
enum HomeTab: String, CaseIterable, Identifiable {
    case tools  = "工具"
    case role   = "角色"
    case growth = "成長"
    case help   = "幫助"
    case diary  = "日記"
    
    var id: String { rawValue }
}
