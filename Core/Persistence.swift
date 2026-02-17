import Foundation
import SwiftUI

enum Persistence {
    static func load<T: Decodable>(_ type: T.Type, key: String, defaultValue: T) -> T {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(T.self, from: data)
        else { return defaultValue }
        return decoded
    }
    
    static func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
