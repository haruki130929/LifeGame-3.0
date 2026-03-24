import SwiftData
import Foundation

@Model
final class KeyValueRecord {
    var key: String
    var data: Data
    var updatedAt: Date

    init(key: String, data: Data) {
        self.key = key
        self.data = data
        self.updatedAt = .now
    }
}
