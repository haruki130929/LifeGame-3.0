import Foundation

enum SafeLoad {
    /// 嘗試載入；失敗回 defaultValue，並保留壞檔備份（.corrupt）
    static func loadOrDefault<T: Codable>(
        store: FileStore,
        filename: String,
        defaultValue: T
    ) -> T {
        do {
            return try store.load(T.self, from: filename)
        } catch {
            // 壞檔備份：避免使用者資料直接消失
            do {
                let badURL = store.url(for: filename)
                let backupURL = store.url(for: filename + ".corrupt.\(Int(Date().timeIntervalSince1970))")
                if FileManager.default.fileExists(atPath: badURL.path) {
                    try FileManager.default.copyItem(at: badURL, to: backupURL)
                }
            } catch {
                // 忽略備份失敗
            }
            return defaultValue
        }
    }
}
