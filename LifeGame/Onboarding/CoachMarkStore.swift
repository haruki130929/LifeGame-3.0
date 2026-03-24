import SwiftUI
import Combine

/// 管理所有情境式教學提示的顯示狀態
final class CoachMarkStore: ObservableObject {

    /// 定義所有 coach mark 步驟（Full + Quick 共用同一個 enum）
    enum Mark: String, CaseIterable {
        // Full Mode 步驟
        case drawerButton   // 左上角選單按鈕
        case rightPanel     // 右上角工具欄按鈕
        case fabButton      // 右下角 FAB
        case tabEdit        // 時段名稱旁的編輯

        // Quick Mode 步驟
        case quickSwipe     // 卡片左右滑動
        case quickSettings  // 右下角設定按鈕
    }

    /// Full Mode 教學流程
    static let fullSequence: [Mark] = [.drawerButton, .rightPanel, .fabButton, .tabEdit]
    /// Quick Mode 教學流程
    static let quickSequence: [Mark] = [.quickSwipe, .quickSettings]

    /// 目前正在顯示的步驟（nil = 不顯示）
    @Published var currentMark: Mark?

    /// 目前使用的教學序列
    private(set) var activeSequence: [Mark] = []

    /// 供 Overlay 讀取目前的教學序列（用於計算步驟進度）
    var activeSequenceForDisplay: [Mark] {
        activeSequence.isEmpty ? Self.fullSequence : activeSequence
    }

    /// 是否已完成整套引導
    private var allCompleted: Bool {
        get {
            Self.migrateLegacyIfNeeded()
            return StorageManager.load(Bool.self, forKey: "onboarding.coachMarksCompleted") ?? false
        }
        set { StorageManager.save(newValue, forKey: "onboarding.coachMarksCompleted") }
    }

    private static let legacyKey = "coach_marks_completed_v1"
    private static func migrateLegacyIfNeeded() {
        let ud = UserDefaults.standard
        guard ud.bool(forKey: legacyKey) else { return }
        StorageManager.save(true, forKey: "onboarding.coachMarksCompleted")
        ud.removeObject(forKey: legacyKey)
    }

    /// 進入主頁面時呼叫，根據模式啟動對應教學序列
    func startIfNeeded(isQuickMode: Bool = false) {
        guard !allCompleted else { return }
        guard currentMark == nil else { return }

        activeSequence = isQuickMode ? Self.quickSequence : Self.fullSequence

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self, self.currentMark == nil, !self.allCompleted else { return }
            self.currentMark = self.activeSequence.first
        }
    }

    /// 進入下一步
    func next() {
        guard let current = currentMark else { return }
        guard let idx = activeSequence.firstIndex(of: current) else {
            // 找不到就直接結束
            currentMark = nil
            allCompleted = true
            return
        }

        let nextIdx = idx + 1
        if nextIdx < activeSequence.count {
            currentMark = activeSequence[nextIdx]
        } else {
            currentMark = nil
            allCompleted = true
        }
    }

    /// 跳過全部
    func skipAll() {
        currentMark = nil
        allCompleted = true
    }

    /// 從設定頁重新播放新手引導
    func restart(isQuickMode: Bool = false) {
        allCompleted = false
        currentMark = nil
        activeSequence = isQuickMode ? Self.quickSequence : Self.fullSequence

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            self.currentMark = self.activeSequence.first
        }
    }
}
