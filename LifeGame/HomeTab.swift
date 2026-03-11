import Foundation

// MARK: - 動態切頁選擇（取代舊的固定 HomeTab enum）

enum TabSelection: Equatable, Hashable {
    case tab(UUID)   // 所有切頁都用 CustomTab 的 UUID 識別
}
