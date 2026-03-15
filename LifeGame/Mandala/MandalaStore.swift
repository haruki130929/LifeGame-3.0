import Foundation
import Combine
import SwiftUI

@MainActor
final class MandalaStore: ObservableObject {

    struct Document: Identifiable, Codable, Equatable {
        var id: UUID = UUID()
        var name: String = "圖表 1"
        var goal: String
        var themes: [String]              // 8 個
        var actions: [[String]]           // 8 組，每組 8 個
        var cellColors: [String: String] = [:]  // "row-col" → hex color

        static func empty(name: String = "圖表 1") -> Document {
            Document(
                name: name,
                goal: "",
                themes: Array(repeating: "", count: 8),
                actions: Array(repeating: Array(repeating: "", count: 8), count: 8)
            )
        }
    }

    @Published var documents: [Document] {
        didSet { save() }
    }

    @Published var currentIndex: Int = 0
    /// 每次顏色變更時更新，讓 SwiftUI 偵測到變化並重新渲染
    @Published private(set) var colorRevision = UUID()

    var doc: Document {
        get {
            guard documents.indices.contains(currentIndex) else {
                return .empty()
            }
            return documents[currentIndex]
        }
        set {
            guard documents.indices.contains(currentIndex) else { return }
            documents[currentIndex] = newValue
        }
    }

    private let keyV2 = "mandala.documents.v2"
    private let keyV1 = "mandala.document.v1"

    init() {
        // 嘗試載入 v2
        if let docs = StorageManager.load([Document].self, forKey: keyV2), !docs.isEmpty {
            self.documents = docs
        }
        // 遷移 v1
        else if let legacy = StorageManager.load(LegacyDocument.self, forKey: keyV1) {
            let migrated = Document(
                name: "圖表 1",
                goal: legacy.goal,
                themes: legacy.themes,
                actions: legacy.actions
            )
            self.documents = [migrated]
        }
        // 全新
        else {
            self.documents = [.empty()]
        }
    }

    private func save() {
        StorageManager.save(documents, forKey: keyV2)
    }

    // MARK: - 多圖表操作

    func addDocument() {
        let name = "圖表 \(documents.count + 1)"
        documents.append(.empty(name: name))
        currentIndex = documents.count - 1
    }

    func deleteDocument(at index: Int) {
        guard documents.count > 1 else { return }
        documents.remove(at: index)
        if currentIndex >= documents.count {
            currentIndex = documents.count - 1
        }
    }

    func reset() {
        doc = .empty(name: doc.name)
    }

    // MARK: - 格子交換

    func swapCells(from: (Int, Int), to: (Int, Int)) {
        let fromText = cellText(row: from.0, col: from.1)
        let toText = cellText(row: to.0, col: to.1)
        setCellText(row: from.0, col: from.1, text: toText)
        setCellText(row: to.0, col: to.1, text: fromText)
    }

    // MARK: - 格子顏色

    func setCellColor(row: Int, col: Int, hex: String?) {
        updateCellColors(["\(row)-\(col)": hex])
    }

    /// 批次更新多個格子的顏色，只觸發一次 @Published
    func updateCellColors(_ changes: [String: String?]) {
        guard documents.indices.contains(currentIndex) else { return }
        var updated = documents[currentIndex]
        for (key, hex) in changes {
            if let hex {
                updated.cellColors[key] = hex
            } else {
                updated.cellColors.removeValue(forKey: key)
            }
        }
        documents[currentIndex] = updated
        colorRevision = UUID()
    }

    func cellColor(row: Int, col: Int) -> String? {
        doc.cellColors["\(row)-\(col)"]
    }

    // MARK: - 內部 Helper

    /// 8 個主題格的 (row, col)
    private let themePositions: [(Int, Int)] = [
        (3, 3), (3, 4), (3, 5),
        (4, 3),         (4, 5),
        (5, 3), (5, 4), (5, 5),
    ]

    private let eightOffsets: [(Int, Int)] = [
        (0, 0), (0, 1), (0, 2),
        (1, 0),         (1, 2),
        (2, 0), (2, 1), (2, 2),
    ]

    private func cellText(row: Int, col: Int) -> String {
        if row == 4 && col == 4 { return doc.goal }
        if let t = themePositions.firstIndex(where: { $0.0 == row && $0.1 == col }) {
            return doc.themes[t]
        }
        if let addr = actionAddress(row: row, col: col) {
            return doc.actions[addr.0][addr.1]
        }
        return ""
    }

    private func setCellText(row: Int, col: Int, text: String) {
        if row == 4 && col == 4 {
            doc.goal = text
            return
        }
        if let t = themePositions.firstIndex(where: { $0.0 == row && $0.1 == col }) {
            doc.themes[t] = text
            return
        }
        if let addr = actionAddress(row: row, col: col) {
            doc.actions[addr.0][addr.1] = text
            return
        }
    }

    private func actionAddress(row: Int, col: Int) -> (Int, Int)? {
        let blockRow = row / 3
        let blockCol = col / 3
        guard !(blockRow == 1 && blockCol == 1) else { return nil }

        let localRow = row % 3
        let localCol = col % 3
        guard !(localRow == 1 && localCol == 1) else { return nil }

        let themeRow = 3 + blockRow
        let themeCol = 3 + blockCol
        guard let themeIndex = themePositions.firstIndex(where: { $0.0 == themeRow && $0.1 == themeCol }) else { return nil }
        guard let actionIndex = eightOffsets.firstIndex(where: { $0.0 == localRow && $0.1 == localCol }) else { return nil }

        return (themeIndex, actionIndex)
    }

    // MARK: - v1 遷移用
    private struct LegacyDocument: Codable {
        var goal: String
        var themes: [String]
        var actions: [[String]]
    }
}
