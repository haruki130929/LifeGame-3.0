import SwiftUI
import SwiftData
import CloudKit
import CoreData

@MainActor
@Observable
final class StorageCoordinator {
    private(set) var modelContainer: ModelContainer
    private(set) var isMigrating = false
    private(set) var switchError: String?

    private let configuration: StorageConfiguration
    private let migrationManager = MigrationManager()
    private let schema: Schema

    // MARK: - Model type registry

    private static var registeredModelTypes: [any PersistentModel.Type] = [
        KeyValueRecord.self
    ]

    static func registerModelType(_ type: any PersistentModel.Type) {
        guard !registeredModelTypes.contains(where: { $0 == type }) else { return }
        registeredModelTypes.append(type)
    }

    // MARK: - Init

    init(configuration: StorageConfiguration) throws {
        self.configuration = configuration
        self.schema = Schema(Self.registeredModelTypes)

        Self.ensureStoreDirectoryExists()
        Self.migrateStoresIntoGroupIfNeeded()   // ⚠️ 必須在開任何 ModelContainer「之前」

        let pendingMode = configuration.pendingMode
        let currentMode = configuration.currentMode

        if let pending = pendingMode, pending != currentMode {
            // 有待切換的模式 → 直接建立新模式容器（不做遷移，避免同時建兩個容器）
            // SwiftData 不允許同一 Schema 同時有兩個 ModelContainer
            do {
                self.modelContainer = try Self.createContainer(mode: pending, schema: schema)
                configuration.confirmModeSwitch()
                switchError = nil
                debugLog("✅ 儲存模式已切換：\(currentMode) → \(pending)")
            } catch {
                // 新模式失敗 → 用當前模式啟動，但保留 pending 讓下次再試
                debugLog("⚠️ 切換模式失敗，保留 pending 下次再試：\(error)")
                switchError = error.localizedDescription
                self.modelContainer = try Self.createContainer(mode: currentMode, schema: schema)
            }
        } else {
            self.modelContainer = try Self.createContainer(
                mode: currentMode,
                schema: schema
            )
        }

    }

    // MARK: - Remote change notification

    /// 當 CloudKit 完成 import（從雲端拉取資料）時發送的通知名稱
    /// 各 Store 可監聽此通知來重新載入資料
    static let didReceiveRemoteChange = Notification.Name("StorageCoordinator.didReceiveRemoteChange")

    // MARK: - Container creation

    private static func createContainer(
        mode: StorageMode,
        schema: Schema
    ) throws -> ModelContainer {
        let config: ModelConfiguration
        switch mode {
        case .local:
            config = ModelConfiguration(
                "LifeGameLocal",
                schema: schema,
                url: groupLocalStoreURL,
                cloudKitDatabase: .none
            )
        case .iCloud:
            // 明確指定 App Group 容器內的 url（Widget 才讀得到），
            // 並 pin 正式 CloudKit 容器（取代 .automatic，避免容器綁定歧義）
            config = ModelConfiguration(
                "LifeGameCloud",
                schema: schema,
                url: groupCloudStoreURL,
                cloudKitDatabase: .private("iCloud.com.haruki.lifegame2")
            )
        }

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            debugLog("❌ 建立容器失敗 (\(mode)):", error)
            throw StorageError.containerCreationFailed(underlying: error)
        }
    }

    // MARK: - Store URLs

    /// 舊版 store 位置（app 私有目錄）— 僅作為一次性搬遷的「來源」
    private static var legacyStoreDirectory: URL {
        URL.applicationSupportDirectory.appendingPathComponent("LifeGame", isDirectory: true)
    }
    private static var legacyLocalStoreURL: URL {
        legacyStoreDirectory.appendingPathComponent("Local.store")
    }

    /// 新版 store 位置（App Group 共享容器）— Widget 也讀得到。
    /// 若 App Group entitlement 缺失，fallback 回舊位置（app 仍可運作，只是無法分享給 Widget）。
    private static var groupStoreDirectory: URL {
        guard let base = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SharedConstants.appGroupID
        ) else {
            debugLog("⚠️ App Group 容器不可用，store fallback 回 app 私有目錄（Widget 將讀不到資料）")
            return legacyStoreDirectory
        }
        return base.appendingPathComponent("LifeGame", isDirectory: true)
    }
    private static var groupLocalStoreURL: URL {
        groupStoreDirectory.appendingPathComponent("Local.store")
    }
    private static var groupCloudStoreURL: URL {
        groupStoreDirectory.appendingPathComponent("Cloud.store")
    }

    private static func ensureStoreDirectoryExists() {
        let dir = groupStoreDirectory
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    // MARK: - 一次性搬遷：把舊 store 複製進 App Group 容器
    //
    // 規則：① 只「複製」不刪除（舊檔留作備援，v1 不清掉）
    //      ② .store / -wal / -shm 三個一起複製，否則會丟失未 flush 的寫入
    //      ③ 必須在開任何 ModelContainer「之前」執行，否則 SwiftData 會先在新位置
    //         建一個空 store，搬遷就來不及（會看起來像整包資料不見）
    //      ④ 目的地已存在就跳過（可重入、不蓋掉較新的資料）
    private static let migrationFlagKey = "lifegame.storage.didMigrateToAppGroup.v1"

    private static func migrateStoresIntoGroupIfNeeded() {
        let flags = UserDefaults.standard
        guard !flags.bool(forKey: migrationFlagKey) else { return }

        let fm = FileManager.default
        let src = legacyLocalStoreURL
        let dest = groupLocalStoreURL

        // 來源存在、且 App Group 容器確實可用（dest 不等於 src）、且目的地還沒有 → 才複製
        if dest.path != src.path,
           fm.fileExists(atPath: src.path),
           !fm.fileExists(atPath: dest.path) {
            for suffix in ["", "-wal", "-shm"] {
                let s = URL(fileURLWithPath: src.path + suffix)
                let d = URL(fileURLWithPath: dest.path + suffix)
                if fm.fileExists(atPath: s.path) {
                    try? fm.copyItem(at: s, to: d)
                }
            }
            debugLog("📦 已將本機 store 複製進 App Group 容器（舊檔保留作備援）")
        }
        // 註：iCloud 模式的 store 沒有可控的固定路徑，不嘗試搬。改 url 後
        // CloudKit 會把資料重新下載到新位置（資料在雲端、本機鏡像可丟）。

        flags.set(true, forKey: migrationFlagKey)
    }

    // MARK: - Mode switching（只記錄偏好，重啟後生效）

    /// 排程切換模式：儲存偏好，下次啟動時自動遷移
    func scheduleSwitch(to newMode: StorageMode) {
        guard newMode != configuration.currentMode else { return }

        if newMode == .iCloud {
            guard FileManager.default.ubiquityIdentityToken != nil else {
                return  // iCloud 不可用，不做任何事
            }
        }

        configuration.setPendingMode(newMode)
    }

    /// 取消排程的切換
    func cancelPendingSwitch() {
        configuration.clearPendingMode()
    }

    /// 是否有等待中的模式切換
    var hasPendingSwitch: Bool {
        configuration.pendingMode != nil
    }

    /// 等待中的目標模式
    var pendingMode: StorageMode? {
        configuration.pendingMode
    }

    // MARK: - Convenience

    var mainContext: ModelContext {
        modelContainer.mainContext
    }

    // MARK: - CloudKit 去重

    /// 啟動時清理 CloudKit 同步造成的重複資料
    func deduplicateIfNeeded() {
        let context = mainContext

        // 1. KeyValueRecord：同 key 只留 updatedAt 最新的
        do {
            let allKV = try context.fetch(FetchDescriptor<KeyValueRecord>())
            let grouped = Dictionary(grouping: allKV, by: \.key)
            for (key, records) in grouped where records.count > 1 {
                let sorted = records.sorted { $0.updatedAt > $1.updatedAt }
                guard let newest = sorted.first else { continue }
                // 集合型 → 合併保留兩台的資料；其餘 → 取最新（LWW）
                let resolved = KeyValueMergeRegistry.resolvedData(forKey: key, records: records) ?? newest.data
                newest.data = resolved
                newest.updatedAt = .now
                for dup in sorted.dropFirst() {
                    context.delete(dup)
                }
                debugLog("🧹 KeyValueRecord 收斂: key=\(key), \(records.count) 筆 → 1\(KeyValueMergeRegistry.hasMerger(for: key) ? "（合併）" : "（取最新）")")
            }
        } catch {
            debugLog("⚠️ KeyValueRecord 去重失敗: \(error)")
        }

        // 2. BagItemModel：同 name + icon 只留一筆（保留 isRequired=true 優先）
        do {
            let allBag = try context.fetch(FetchDescriptor<BagItemModel>())
            let grouped = Dictionary(grouping: allBag) { "\($0.name)|\($0.icon)" }
            for (_, items) in grouped where items.count > 1 {
                // 優先保留 isRequired=true 或 isChecked=true 的
                let sorted = items.sorted { a, b in
                    if a.isRequired != b.isRequired { return a.isRequired }
                    if a.isChecked != b.isChecked { return a.isChecked }
                    return false
                }
                for dup in sorted.dropFirst() {
                    context.delete(dup)
                }
                debugLog("🧹 清理重複 BagItemModel: \(items.first?.name ?? ""), 刪除 \(sorted.count - 1) 筆")
            }
        } catch {
            debugLog("⚠️ BagItemModel 去重失敗: \(error)")
        }

        // 3. DailyLogRecord：同 id 只留一筆（保留最新 date）
        do {
            let allLog = try context.fetch(FetchDescriptor<DailyLogRecord>())
            let grouped = Dictionary(grouping: allLog, by: \.id)
            for (id, records) in grouped where records.count > 1 {
                let sorted = records.sorted { $0.date > $1.date }
                for dup in sorted.dropFirst() {
                    context.delete(dup)
                }
                debugLog("🧹 清理重複 DailyLogRecord: id=\(id), 刪除 \(sorted.count - 1) 筆")
            }
        } catch {
            debugLog("⚠️ DailyLogRecord 去重失敗: \(error)")
        }

        context.safeSave()
    }

    // MARK: - CloudKit 同步診斷

    /// 啟動時呼叫，印出 CloudKit 同步狀態與資料筆數
    func diagnoseiCloudSync() {
        guard configuration.currentMode == .iCloud else {
            debugLog("📦 儲存模式：本機（不使用 iCloud）")
            return
        }

        debugLog("☁️ 儲存模式：iCloud")
        debugLog("☁️ ubiquityIdentityToken: \(FileManager.default.ubiquityIdentityToken != nil ? "有（已登入 iCloud）" : "無（未登入 iCloud）")")

        // 檢查 CloudKit 帳號狀態
        CKContainer(identifier: "iCloud.com.haruki.lifegame2").accountStatus { status, error in
            let statusText: String
            switch status {
            case .available:      statusText = "✅ available（正常）"
            case .noAccount:      statusText = "❌ noAccount（未登入）"
            case .restricted:     statusText = "⚠️ restricted（受限）"
            case .couldNotDetermine: statusText = "❓ couldNotDetermine"
            case .temporarilyUnavailable: statusText = "⏳ temporarilyUnavailable"
            @unknown default:     statusText = "❓ unknown(\(status.rawValue))"
            }
            debugLog("☁️ CloudKit 帳號狀態：\(statusText)")
            if let error {
                debugLog("☁️ CloudKit 帳號錯誤：\(error)")
            }

            // 已選 iCloud 模式但帳號不可用 → 主動提示使用者「資料其實沒在同步」
            let warning: String?
            switch status {
            case .noAccount:  warning = "尚未登入 iCloud，資料暫時不會跨裝置同步"
            case .restricted: warning = "iCloud 受到限制，資料暫時不會跨裝置同步"
            default:          warning = nil
            }
            if let warning {
                Task { @MainActor in ErrorManager.shared.showError(warning) }
            }
        }

        // 查詢目前 SwiftData 裡有多少筆 KeyValueRecord
        Task { @MainActor in
            do {
                let descriptor = FetchDescriptor<KeyValueRecord>()
                let records = try mainContext.fetch(descriptor)
                debugLog("☁️ SwiftData KeyValueRecord 筆數：\(records.count)")
                for record in records {
                    debugLog("   📝 key: \(record.key), 大小: \(record.data.count) bytes, 更新: \(record.updatedAt)")
                }
            } catch {
                debugLog("☁️ 查詢 KeyValueRecord 失敗：\(error)")
            }

            // 監聽 NSPersistentCloudKitContainer 的同步事件
            listenForCloudKitEvents()
        }
    }

    /// 監聽 CloudKit 同步事件通知
    private func listenForCloudKitEvents() {
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event else { return }

            let typeText: String
            switch event.type {
            case .setup:  typeText = "setup"
            case .import: typeText = "import（從雲端拉取）"
            case .export: typeText = "export（推送到雲端）"
            @unknown default: typeText = "unknown"
            }

            if event.endDate != nil {
                // 事件結束
                if let error = event.error {
                    debugLog("☁️ CloudKit 同步 [\(typeText)] ❌ 失敗：\(error)")
                } else {
                    debugLog("☁️ CloudKit 同步 [\(typeText)] ✅ 完成")
                    // 從雲端拉取完成 → 去重 + 通知各 Store 重新載入
                    if event.type == .import {
                        self.deduplicateIfNeeded()
                        NotificationCenter.default.post(name: StorageCoordinator.didReceiveRemoteChange, object: nil)
                    }
                }
            } else {
                debugLog("☁️ CloudKit 同步 [\(typeText)] ⏳ 開始...")
            }
        }
        debugLog("☁️ 已開始監聽 CloudKit 同步事件")
    }
}
