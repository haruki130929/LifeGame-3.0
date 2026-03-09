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
        self.modelContainer = try Self.createContainer(
            mode: configuration.currentMode,
            schema: schema
        )
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
                url: cloudStoreURL,
                cloudKitDatabase: .automatic
            )
        }

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
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

    private static var cloudStoreURL: URL {
        storeDirectory.appendingPathComponent("Cloud.store")
    }

    // MARK: - Mode switching

    func switchMode(to newMode: StorageMode) async throws {
        guard newMode != configuration.currentMode else { return }
        guard !isMigrating else { throw StorageError.migrationInProgress }

        if newMode == .iCloud {
            guard FileManager.default.ubiquityIdentityToken != nil else {
                throw StorageError.iCloudUnavailable
            }
        }

        isMigrating = true
        defer { isMigrating = false }

        let destinationContainer = try Self.createContainer(
            mode: newMode,
            schema: schema
        )

        try migrationManager.migrateAllData(
            from: modelContainer,
            to: destinationContainer,
            modelTypes: Self.registeredModelTypes
        )

        modelContainer = destinationContainer
        configuration.setMode(newMode)
    }

    // MARK: - Convenience

    var mainContext: ModelContext {
        modelContainer.mainContext
    }
}
