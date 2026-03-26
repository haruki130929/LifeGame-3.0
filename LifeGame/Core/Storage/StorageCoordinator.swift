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
            config = ModelConfiguration(
                "LifeGameCloud",
                schema: schema,
                cloudKitDatabase: .automatic
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
                }
            } else {
                debugLog("☁️ CloudKit 同步 [\(typeText)] ⏳ 開始...")
            }
        }
        debugLog("☁️ 已開始監聽 CloudKit 同步事件")
    }
}
