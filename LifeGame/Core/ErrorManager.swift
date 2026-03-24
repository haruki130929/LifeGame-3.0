import SwiftUI
import Combine

/// 統一的錯誤通知管理器
/// 使用方式：ErrorManager.shared.show("儲存失敗", detail: error.localizedDescription)
final class ErrorManager: ObservableObject {

    static let shared = ErrorManager()

    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let icon: String
        let message: String
        let detail: String?
        let level: Level

        enum Level: Equatable {
            case error      // 紅色
            case warning    // 橘色
            case info       // 藍色
            case success    // 綠色
        }

        static func == (lhs: Toast, rhs: Toast) -> Bool { lhs.id == rhs.id }
    }

    @Published var currentToast: Toast?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    // MARK: - Public API

    func show(_ message: String, detail: String? = nil, level: Toast.Level = .error) {
        let icon: String
        switch level {
        case .error:   icon = "xmark.circle.fill"
        case .warning: icon = "exclamationmark.triangle.fill"
        case .info:    icon = "info.circle.fill"
        case .success: icon = "checkmark.circle.fill"
        }

        let toast = Toast(icon: icon, message: message, detail: detail, level: level)

        dismissTask?.cancel()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentToast = toast
        }

        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                if self.currentToast?.id == toast.id {
                    self.currentToast = nil
                }
            }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            currentToast = nil
        }
    }

    // MARK: - Convenience

    func showError(_ message: String, error: Error? = nil) {
        let detail = error?.localizedDescription
        debugLog("❌ \(message)" + (detail.map { ": \($0)" } ?? ""))
        show(message, detail: detail, level: .error)
    }

    func showWarning(_ message: String) {
        debugLog("⚠️ \(message)")
        show(message, level: .warning)
    }

    func showSuccess(_ message: String) {
        show(message, level: .success)
    }
}
