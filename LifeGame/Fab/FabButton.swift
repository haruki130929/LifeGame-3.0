import SwiftUI

struct FabButton: View {
    @EnvironmentObject var fab: FabStore
    @EnvironmentObject private var theme: ThemeStore

    @State private var btnScale: CGFloat = 1.0
    @State private var btnRotation: Double = 0
    @State private var isAnimating = false
    @State private var showMenuItems: Bool = false
    @State private var showSubItems: Bool = false

    private let fabCircleSize: CGFloat = 60
    private let itemDelay: Double = 0.04

    // MARK: - Adaptive Colors（從 theme.isDark 決定）
    private var fabCircleBg: Color {
        theme.isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.08)
    }
    private var pillBg: Color {
        theme.isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
    }
    private var pillStroke: Color {
        theme.isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }
    private var subPillBg: Color {
        theme.isDark ? Color.white.opacity(0.18) : Color.black.opacity(0.10)
    }
    private var fabForeground: Color {
        theme.isDark ? .white.opacity(0.95) : Color(.label)
    }
    private var menuForeground: Color {
        theme.isDark ? .white.opacity(0.92) : Color(.label)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            // 功能選單 + 細部選單（底部切齊）
            HStack(alignment: .bottom, spacing: 12) {
                if fab.showSubMenu && fab.isExpanded {
                    subMenuView
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }

                mainMenuView
            }

            mainButton
        }
    }

    @ViewBuilder private var mainMenuView: some View {
        if fab.isExpanded {
            VStack(alignment: .trailing, spacing: 8) {
                ForEach(fab.actions.indices, id: \.self) { index in
                    mainMenuItem(index: index, item: fab.actions[index])
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func mainMenuItem(index: Int, item: FabAction) -> some View {
        // 用 FabStore 的 title(for:) 比對 selectedFeature
        let isSelected: Bool = {
            guard let selected = fab.selectedFeature else { return false }
            return fab.title(for: selected) == item.title
        }()

        return Button {
            item.action()
        } label: {
            HStack(spacing: 8) {
                Text(item.title)
                    .font(.callout.weight(.semibold))
                Image(systemName: item.systemImage)
                    .font(.callout.weight(.semibold))
            }
            .foregroundStyle(menuForeground)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected
                ? (theme.isDark ? Color.white.opacity(0.28) : Color.black.opacity(0.14))
                : pillBg)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    isSelected
                        ? (theme.isDark ? Color.white.opacity(0.4) : Color.black.opacity(0.18))
                        : pillStroke,
                    lineWidth: isSelected ? 1.5 : 1
                )
            )
        }
        .buttonStyle(.plain)
        .opacity(showMenuItems ? 1 : 0)
        .offset(y: showMenuItems ? 0 : 14)
        .scaleEffect(showMenuItems ? 1 : 0.92, anchor: .trailing)
        .animation(
            .spring(response: 0.28, dampingFraction: 0.72)
            .delay(Double(index) * itemDelay),
            value: showMenuItems
        )
    }

    private var subMenuView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ForEach(fab.subActions.indices, id: \.self) { index in
                subMenuItem(index: index, item: fab.subActions[index])
            }
        }
        .onAppear {
            // 確保 subMenuView 出現時觸發動畫
            // onChange 在 view 首次進入 hierarchy 時可能不會觸發
            withAnimation(.spring(response: 0.26, dampingFraction: 0.72)) {
                showSubItems = true
            }
        }
    }

    private func subMenuItem(index: Int, item: FabAction) -> some View {
        Button {
            item.action()
        } label: {
            HStack(spacing: 8) {
                Text(item.title)
                    .font(.callout.weight(.semibold))
                Image(systemName: item.systemImage)
                    .font(.callout.weight(.semibold))
            }
            .foregroundStyle(menuForeground)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(subPillBg)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(
                theme.isDark ? Color.white.opacity(0.20) : Color.black.opacity(0.10),
                lineWidth: 1))
        }
        .buttonStyle(.plain)
        .opacity(showSubItems ? 1 : 0)
        .offset(x: showSubItems ? 0 : 16)
        .scaleEffect(showSubItems ? 1 : 0.92, anchor: .trailing)
        .animation(
            .spring(response: 0.26, dampingFraction: 0.72)
            .delay(Double(index) * itemDelay),
            value: showSubItems
        )
        .onChange(of: fab.showSubMenu) { _, isShowing in
            showSubItems = isShowing
        }
    }

    private var mainButton: some View {
        Button {
            if fab.isExpanded {
                collapseSequence()
            } else {
                expandSequence()
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(fabForeground)
                .frame(width: fabCircleSize, height: fabCircleSize)
                .background(fabCircleBg)
                .clipShape(Circle())
                .overlay(Circle().stroke(
                    theme.isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.08),
                    lineWidth: 1))
                .shadow(color: .black.opacity(theme.isDark ? 0.25 : 0.12), radius: 12, x: 0, y: 8)
                .scaleEffect(btnScale)
                .rotationEffect(.degrees(btnRotation))
        }
        .buttonStyle(.plain)
        .disabled(isAnimating)
    }

    private func expandSequence() {
        guard !isAnimating else { return }
        isAnimating = true
        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.05)) { btnScale = 0.72 }
            try? await Task.sleep(nanoseconds: 80_000_000)
            fab.isExpanded = true
            showMenuItems = false
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                btnRotation = 135; btnScale = 1.28
            }
            showMenuItems = true
            try? await Task.sleep(nanoseconds: 70_000_000)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { btnScale = 1.0 }
            try? await Task.sleep(nanoseconds: 120_000_000)
            isAnimating = false
        }
    }

    private func collapseSequence() {
        guard !isAnimating else { return }
        isAnimating = true
        Task { @MainActor in
            showMenuItems = false
            showSubItems = false
            fab.hideSubMenu()          // 重置細部選單狀態，下次展開乾淨
            let totalDelay = Double(max(fab.actions.count - 1, 0)) * itemDelay
            let waitForItems = UInt64((totalDelay + 0.04) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: waitForItems)
            withAnimation(.easeOut(duration: 0.05)) { btnScale = 0.72 }
            try? await Task.sleep(nanoseconds: 80_000_000)
            fab.isExpanded = false
            withAnimation(.spring(response: 0.22, dampingFraction: 0.80)) {
                btnRotation = 0; btnScale = 1.18
            }
            try? await Task.sleep(nanoseconds: 70_000_000)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { btnScale = 1.0 }
            try? await Task.sleep(nanoseconds: 120_000_000)
            isAnimating = false
        }
    }
}
