import SwiftUI
import Combine

/// 管理 iPhone 顯示模式（一般 / 簡略）及簡略模式的頁面配置
@MainActor
final class PhoneModeStore: ObservableObject {

    @Published var mode: PhoneMode {
        didSet { saveMode() }
    }

    @Published var quickPages: [QuickPage] {
        didSet { savePages() }
    }

    private let modeKey = "phone_mode_v1"
    private let pagesKey = "quick_pages_v1"

    init() {
        self.mode = StorageManager.load(PhoneMode.self, forKey: modeKey) ?? .full
        self.quickPages = StorageManager.load([QuickPage].self, forKey: pagesKey) ?? Self.defaultPages
    }

    // MARK: - 預設頁面

    static let defaultPages: [QuickPage] = [
        QuickPage(featureType: .tomorrowRing, order: 0),
        QuickPage(featureType: .todo, order: 1),
        QuickPage(featureType: .bag, order: 2),
        QuickPage(featureType: .mood, order: 3),
    ]

    // MARK: - CRUD

    func addPage(_ type: QuickFeatureType) {
        guard !quickPages.contains(where: { $0.featureType == type }) else { return }
        let newOrder = (quickPages.map(\.order).max() ?? -1) + 1
        quickPages.append(QuickPage(featureType: type, order: newOrder))
    }

    func removePage(id: UUID) {
        quickPages.removeAll { $0.id == id }
        reindex()
    }

    func movePage(from source: IndexSet, to destination: Int) {
        quickPages.move(fromOffsets: source, toOffset: destination)
        reindex()
    }

    /// 切換某功能是否出現在簡略模式
    func toggle(_ type: QuickFeatureType) {
        if let index = quickPages.firstIndex(where: { $0.featureType == type }) {
            quickPages.remove(at: index)
            reindex()
        } else {
            addPage(type)
        }
    }

    func contains(_ type: QuickFeatureType) -> Bool {
        quickPages.contains { $0.featureType == type }
    }

    // MARK: - Private

    private func reindex() {
        for i in quickPages.indices {
            quickPages[i].order = i
        }
    }

    private func saveMode() {
        StorageManager.save(mode, forKey: modeKey)
    }

    private func savePages() {
        StorageManager.save(quickPages, forKey: pagesKey)
    }
}
