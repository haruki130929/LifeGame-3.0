import Foundation

enum FileStoreError: Error {
    case encodeFailed
    case decodeFailed
}

/// 用 Documents/ 下的 JSON 檔存 Codable
final class FileStore {
    private let fm = FileManager.default
    private let dir: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    init(
        directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.dir = directory
        self.encoder = encoder
        self.decoder = decoder
        
        // 建議：可讀性（debug）
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }
    
    func url(for filename: String) -> URL {
        dir.appendingPathComponent(filename)
    }
    
    func load<T: Decodable>(_ type: T.Type, from filename: String) throws -> T {
        let u = url(for: filename)
        let data = try Data(contentsOf: u)
        return try decoder.decode(T.self, from: data)
    }
    
    func save<T: Encodable>(_ value: T, to filename: String) throws {
        let u = url(for: filename)
        let data = try encoder.encode(value)
        try data.write(to: u, options: [.atomic])
    }
    
    func exists(_ filename: String) -> Bool {
        fm.fileExists(atPath: url(for: filename).path)
    }
    
    func delete(_ filename: String) throws {
        let u = url(for: filename)
        if fm.fileExists(atPath: u.path) {
            try fm.removeItem(at: u)
        }
    }
}
