import SwiftUI
import SwiftData

@MainActor
@Observable
final class StorageCoordinator {
    private(set) var modelContainer: ModelContainer
    private(set) var isMigrating = false

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
                debugLog("✅ 儲存模式已切換：\(currentMode) → \(pending)")
            } catch {
                // 新模式失敗（例如 iCloud 不可用）→ 回退到當前模式
                debugLog("⚠️ 切換模式失敗，回退到 \(currentMode)：\(error)")
                configuration.clearPendingMode()
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
}
