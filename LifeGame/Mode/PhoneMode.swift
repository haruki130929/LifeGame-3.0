import Foundation

/// iPhone 顯示模式
enum PhoneMode: String, Codable, CaseIterable {
    /// 一般模式 — 與 iPad 相同的完整功能
    case full
    /// 簡略模式 — 可左右滑動的快速功能頁
    case quick
}
