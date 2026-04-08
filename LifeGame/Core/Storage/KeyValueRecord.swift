import SwiftData
import Foundation

@Model
final class KeyValueRecord {
    @Attribute(.unique) var key: String = ""
    var data: Data = Data()
    var updatedAt: Date = Date()

    init(key: String, data: Data) {
        self.key = key
        self.data = data
        self.updatedAt = .now
    }
}
