import SwiftUI
import Combine

/// 管理所有情境式教學提示的顯示狀態
final class CoachMarkStore: ObservableObject {

    /// 定義所有 coach mark 步驟
    enum Mark: String, CaseIterable {
        case drawerButton   // 左上角選單按鈕
        case rightPanel     // 右上角工具欄按鈕
        case fabButton      // 右下角 FAB
        case tabEdit        // 時段名稱旁的編輯
    }

    /// 目前正在顯示的步驟（nil = 不顯示）
    @Published var currentMark: Mark?

    /// 各按鈕的螢幕座標中心點（由各 View 用 .global 座標回報）
    @Published var buttonCenters: [Mark: CGPoint] = [:]

    /// 回報某按鈕的螢幕中心點
    func reportCenter(_ center: CGPoint, for mark: Mark) {
        buttonCenters[mark] = center
    }

    /// 是否已完成整套引導
    @AppStorage("coach_marks_completed_v1") private var allCompleted = false

    /// 進入主頁面時呼叫（延遲一點讓按鈕先回報位置）
    func startIfNeeded() {
        guard !allCompleted else { return }
        guard currentMark == nil else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self, self.currentMark == nil, !self.allCompleted else { return }
            self.currentMark = .drawerButton
        }
    }

    /// 進入下一步
    func next() {
        guard let current = currentMark else { return }
        switch current {
        case .drawerButton:
            currentMark = .rightPanel
        case .rightPanel:
            currentMark = .fabButton
        case .fabButton:
            currentMark = .tabEdit
        case .tabEdit:
            currentMark = nil
            allCompleted = true
        }
    }

    /// 跳過全部
    func skipAll() {
        currentMark = nil
        allCompleted = true
    }
}
