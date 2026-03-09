import Foundation

/// 只在 DEBUG 模式下輸出 log，Release build 會被編譯器完全移除
@inline(__always)
func debugLog(_ items: Any..., separator: String = " ") {
    #if DEBUG
    let output = items.map { "\($0)" }.joined(separator: separator)
    Swift.print(output)
    #endif
}
