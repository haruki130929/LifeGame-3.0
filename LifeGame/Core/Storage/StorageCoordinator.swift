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
                url: localStoreURL,
                cloudKitDatabase: .none
            )
        case .iCloud:
            #if DEBUG
            // Debug build 不同步 CloudKit，避免開發資料污染正式環境
            debugLog("⚠️ Debug 模式：iCloud 同步已停用，使用獨立本地儲存")
            config = ModelConfiguration(
                "LifeGameCloudDev",
                schema: schema,
                cloudKitDatabase: .none
            )
            #else
            config = ModelConfiguration(
                "LifeGameCloud",
                schema: schema,
                cloudKitDatabase: .automatic
            )
            #endif
        }

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            debugLog("❌ 建立容器失敗 (\(mode)):", error)
            throw StorageError.containerCreationFailed(underlying: error)
        }
    }

    // MARK: - Store URLs

    private static var storeDirectory: URL {
        URL.applicationSupportDirectory.appendingPathComponent("LifeGame", isDirectory: true)
    }

    private static var localStoreURL: URL {
        storeDirectory.appendingPathComponent("Local.store")
    }

    private static func ensureStoreDirectoryExists() {
        let dir = storeDirectory
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
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
                for dup in sorted.dropFirst() {
                    context.delete(dup)
                }
                debugLog("🧹 清理重複 KeyValueRecord: key=\(key), 刪除 \(sorted.count - 1) 筆")
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
                    // 從雲端拉取完成 → 通知各 Store 重新載入
                    if event.type == .import {
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
