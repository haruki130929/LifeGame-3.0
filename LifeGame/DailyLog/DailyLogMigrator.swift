import Foundation
import SwiftData

@MainActor
final class DailyLogMigrator {
    private let context: ModelContext
    private let fileURL: URL
    
    init(context: ModelContext, filename: String = "daily_logs_v1.json") {
        self.context = context
        // Documents/daily_logs_v1.json
        self.fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
    }
    
    func migrateIfNeeded() {
        // ✅ 旗標改存 SwiftData（透過 StorageManager）
        let didMigrate: Bool = StorageManager.load(Bool.self, forKey: MigrationFlags.didMigrateDailyLogsToSwiftData) ?? false
        guard didMigrate == false else {
            return
        }
        
        // 沒有舊檔就直接標記完成（代表舊資料本來就沒有）
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            StorageManager.save(true, forKey: MigrationFlags.didMigrateDailyLogsToSwiftData)
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            
            let entries = decodeEntries(from: data)
            if entries.isEmpty {
                StorageManager.save(true, forKey: MigrationFlags.didMigrateDailyLogsToSwiftData)
                return
            }
            
            // 先抓現有 id，避免重複插入
            let existingIDs = try fetchExistingIDs()
            
            var inserted = 0
            for e in entries {
                if existingIDs.contains(e.id) { continue }
                context.insert(DailyLogRecord(entry: e))
                inserted += 1
            }
            
            try context.save()
            
            // ✅ 匯入成功後打旗標（你也可以選擇把舊檔改名備份）
            StorageManager.save(true, forKey: MigrationFlags.didMigrateDailyLogsToSwiftData)
            
            // 可選：把舊檔備份起來避免佔空間（先不刪，改名更安全）
            // try backupOldFile()
            
            debugLog("✅ DailyLog migrate done. inserted=\(inserted)")
        } catch {
            // 不打旗標：讓下次還能再試
            debugLog("❌ DailyLog migrate failed: \(error)")
        }
    }
    
    // MARK: - Decode (flexible)
    
    private func decodeEntries(from data: Data) -> [DailyLogEntry] {
        let decoder = JSONDecoder()
        
        // 1) 直接當成 [DailyLogEntry]
        if let arr = try? decoder.decode([DailyLogEntry].self, from: data) {
            return arr
        }
        
        // 2) 嘗試 VersionedBox-like 格式：{ "version": Int, "payload": [...] }
        struct Box: Decodable {
            let version: Int
            let payload: [DailyLogEntry]
        }
        if let box = try? decoder.decode(Box.self, from: data) {
            return box.payload
        }
        
        return []
    }
    
    private func fetchExistingIDs() throws -> Set<UUID> {
        let descriptor = FetchDescriptor<DailyLogRecord>()
        let records = try context.fetch(descriptor)
        return Set(records.map { $0.id })
    }
    
    // 可選：備份舊檔（不建議直接刪，先備份最保險）
    private func backupOldFile() throws {
        let ts = Int(Date().timeIntervalSince1970)
        let backupURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent("daily_logs_v1.json.migrated.\(ts).bak")
        try FileManager.default.moveItem(at: fileURL, to: backupURL)
    }
}
