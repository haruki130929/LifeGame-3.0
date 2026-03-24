import Foundation
import SwiftData

/// 只在 DEBUG 模式下輸出 log，Release build 會被編譯器完全移除
@inline(__always)
func debugLog(_ items: Any..., separator: String = " ") {
    #if DEBUG
    let output = items.map { "\($0)" }.joined(separator: separator)
    Swift.print(output)
    #endif
}

// MARK: - ModelContext 安全存檔

extension ModelContext {
    /// 存檔並在失敗時記錄 log（取代散落各處的 try? context.save()）
    func safeSave(file: String = #file, line: Int = #line) {
        do {
            try save()
        } catch {
            let fileName = (file as NSString).lastPathComponent
            debugLog("❌ ModelContext.save() 失敗 [\(fileName):\(line)]: \(error)")
            ErrorManager.shared.showError("資料儲存失敗", error: error)
        }
    }
}
