import Foundation
import Combine
import SwiftUI

/// 任務水族箱的資料層 —— 完全沿用 TodoQuadrantStore 的儲存／同步骨架。
/// 任務（魚）持久化並透過 CloudKit 跨裝置同步；面板的展開狀態僅本機畫面用，不同步。
@MainActor
final class AquariumStore: ObservableObject {

    private let storageKey = "aquarium_v1"

    /// 持久化 + 跨裝置同步的任務（魚）清單
    @Published var tasks: [AquariumTask] = [] {
        didSet { if !isReloading { save() } }
    }

    /// 浮動面板展開／收合（僅本機畫面狀態，不持久化、不同步）
    @Published var isExpanded: Bool = false

    private var syncHelper: StoreSyncHelper?
    private var isReloading = false

    init() {
        load()
        // 監聽 App 回前景 + CloudKit 遠端變更 → 重新載入（即時跨裝置同步）
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    func reloadFromStorage() {
        isReloading = true
        if let saved: [AquariumTask] = StorageManager.load([AquariumTask].self, forKey: storageKey) {
            tasks = saved
        } else {
            tasks = []
        }
        isReloading = false
    }

    // MARK: - Mutations

    /// 手動放一隻魚進缸
    func add(title: String, type: FishType) {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        tasks.insert(AquariumTask(title: t, type: type), at: 0)
    }

    /// 完成任務 → 從清單移除（魚游出水缸消失）
    func complete(_ id: UUID) {
        tasks.removeAll { $0.id == id }
    }

    func task(_ id: UUID) -> AquariumTask? {
        tasks.first { $0.id == id }
    }

    // MARK: - 生態平衡

    var counts: [FishType: Int] {
        Dictionary(grouping: tasks, by: \.type).mapValues(\.count)
    }

    /// 失衡時的柔性提示（不扣分、魚不會死）。
    /// 條件：總數 ≥ 3，且「某類佔比 > 55% 且有類型掛零」或「某類佔比 > 65%」。
    var imbalanceTip: String? {
        let total = tasks.count
        guard total >= 3 else { return nil }
        let c = counts
        guard let maxType = FishType.allCases.max(by: { (c[$0] ?? 0) < (c[$1] ?? 0) }) else { return nil }
        let maxCount = c[maxType] ?? 0
        let zeros = FishType.allCases.filter { (c[$0] ?? 0) == 0 }
        let ratio = Double(maxCount) / Double(total)
        if ratio > 0.55 && !zeros.isEmpty {
            let missing = zeros.map(\.label).joined(separator: "、")
            return "\(maxType.label)魚偏多，\(missing)魚一隻都沒有 — 換個方向吧"
        } else if ratio > 0.65 {
            return "\(maxType.label)任務堆很多，記得均衡一下其他類型"
        }
        return nil
    }

    // MARK: - Persistence

    private func save() {
        StorageManager.save(tasks, forKey: storageKey)
    }

    private func load() {
        // 載入時設 isReloading → 不觸發 didSet 的 save()，避免冷啟動蓋掉尚未合併的外部變更。
        isReloading = true
        defer { isReloading = false }
        if let saved: [AquariumTask] = StorageManager.load([AquariumTask].self, forKey: storageKey) {
            tasks = saved
        }
    }
}
