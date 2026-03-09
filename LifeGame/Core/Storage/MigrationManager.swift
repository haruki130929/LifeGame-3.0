import SwiftData
import Foundation

@MainActor
final class MigrationManager {

    func migrateAllData(
        from source: ModelContainer,
        to destination: ModelContainer,
        modelTypes: [any PersistentModel.Type]
    ) throws {
        let sourceContext = ModelContext(source)
        let destinationContext = ModelContext(destination)
        destinationContext.autosaveEnabled = false

        for modelType in modelTypes {
            try migrateModelType(
                modelType,
                from: sourceContext,
                to: destinationContext
            )
        }

        do {
            try destinationContext.save()
        } catch {
            throw StorageError.migrationFailed(underlying: error)
        }
    }

    private func migrateModelType(
        _ modelType: any PersistentModel.Type,
        from source: ModelContext,
        to destination: ModelContext
    ) throws {
        func migrate<T: PersistentModel>(_ type: T.Type) throws {
            let descriptor = FetchDescriptor<T>()
            let items = try source.fetch(descriptor)
            for item in items {
                destination.insert(item)
            }
        }
        do {
            try _openExistential(modelType, do: migrate)
        } catch {
            throw StorageError.migrationFailed(underlying: error)
        }
    }
}
