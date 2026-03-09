import Foundation

enum StorageError: LocalizedError {
    case containerCreationFailed(underlying: Error)
    case migrationFailed(underlying: Error)
    case migrationInProgress
    case iCloudUnavailable
    case fetchFailed(modelType: String, underlying: Error)
    case saveFailed(underlying: Error)
    case keyValueEncodingFailed(key: String)
    case keyValueDecodingFailed(key: String, targetType: String)

    var errorDescription: String? {
        switch self {
        case .containerCreationFailed(let error):
            "無法建立儲存容器：\(error.localizedDescription)"
        case .migrationFailed(let error):
            "資料遷移失敗：\(error.localizedDescription)"
        case .migrationInProgress:
            "資料遷移正在進行中"
        case .iCloudUnavailable:
            "此裝置無法使用 iCloud"
        case .fetchFailed(let modelType, let error):
            "讀取 \(modelType) 失敗：\(error.localizedDescription)"
        case .saveFailed(let error):
            "儲存失敗：\(error.localizedDescription)"
        case .keyValueEncodingFailed(let key):
            "編碼 '\(key)' 的值失敗"
        case .keyValueDecodingFailed(let key, let targetType):
            "解碼 '\(key)' 為 \(targetType) 失敗"
        }
    }
}
