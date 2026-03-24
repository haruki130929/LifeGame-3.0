import SwiftUI

/// 貼在最上層的 Toast 通知 overlay
/// 用法：在 App 根 View 加上 .overlay { ToastOverlay() }
struct ToastOverlay: View {
    @ObservedObject private var manager = ErrorManager.shared

    var body: some View {
        VStack {
            if let toast = manager.currentToast {
                toastView(toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture { manager.dismiss() }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            Spacer()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: manager.currentToast)
    }

    private func toastView(_ toast: ErrorManager.Toast) -> some View {
        HStack(spacing: 10) {
            Image(systemName: toast.icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(iconColor(toast.level))

            VStack(alignment: .leading, spacing: 2) {
                Text(toast.message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                if let detail = toast.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            Button {
                manager.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(borderColor(toast.level), lineWidth: 1)
        }
    }

    private func iconColor(_ level: ErrorManager.Toast.Level) -> Color {
        switch level {
        case .error:   return .red
        case .warning: return .orange
        case .info:    return .blue
        case .success: return .green
        }
    }

    private func borderColor(_ level: ErrorManager.Toast.Level) -> Color {
        iconColor(level).opacity(0.3)
    }
}
