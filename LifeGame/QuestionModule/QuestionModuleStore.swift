import Foundation
import Combine
import SwiftUI

@MainActor
final class QuestionModuleStore: ObservableObject {
    @Published private(set) var modules: [DailyLogModule] {
        didSet { save() }
    }

    private let key = "question_modules_v1"

    init() {
        if let saved: [DailyLogModule] = StorageManager.load([DailyLogModule].self, forKey: key) {
            self.modules = saved
        } else {
            // 首次啟動：建立 9 個內建模組，全部啟用
            self.modules = Self.defaultBuiltInModules()
        }
    }

    // MARK: - 預設內建模組

    static func defaultBuiltInModules() -> [DailyLogModule] {
        ModuleKind.builtInCases.enumerated().map { index, kind in
            DailyLogModule(kind: kind, isEnabled: true, sortOrder: index)
        }
    }

    // MARK: - Computed

    /// 已啟用的模組，按 sortOrder 排序
    var enabledModules: [DailyLogModule] {
        modules
            .filter(\.isEnabled)
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// 已啟用的自訂模組（日記用）
    var enabledCustomModules: [DailyLogModule] {
        modules
            .filter { $0.isEnabled && $0.kind == .custom }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - 開關

    func toggle(id: UUID) {
        guard let i = modules.firstIndex(where: { $0.id == id }) else { return }
        modules[i].isEnabled.toggle()
    }

    // MARK: - 排序

    func reorder(from source: IndexSet, to destination: Int) {
        var sorted = modules.sorted { $0.sortOrder < $1.sortOrder }
        sorted.move(fromOffsets: source, toOffset: destination)
        // 重新指派 sortOrder
        for (index, _) in sorted.enumerated() {
            sorted[index].sortOrder = index
        }
        modules = sorted
    }

    // MARK: - 自訂模組 CRUD

    func addCustomModule(_ module: DailyLogModule) {
        var newModule = module
        newModule.sortOrder = (modules.map(\.sortOrder).max() ?? 0) + 1
        modules.append(newModule)
    }

    func updateCustomModule(_ module: DailyLogModule) {
        guard let i = modules.firstIndex(where: { $0.id == module.id }) else { return }
        modules[i] = module
    }

    func removeCustomModule(id: UUID) {
        modules.removeAll { $0.id == id && $0.kind == .custom }
    }

    /// 刪除任何模組（含內建）
    func removeModule(id: UUID) {
        modules.removeAll { $0.id == id }
    }

    /// 更新內建模組（允許修改 title、icon、questions）
    func updateBuiltInModule(_ module: DailyLogModule) {
        guard let idx = modules.firstIndex(where: { $0.id == module.id }) else { return }
        modules[idx].title = module.title
        modules[idx].icon = module.icon
        modules[idx].questions = module.questions
    }

    // MARK: - Persistence

    private func save() {
        StorageManager.save(modules, forKey: key)
    }
}
