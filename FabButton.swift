import SwiftUI

struct FabButton: View {
    @EnvironmentObject var fab: FabStore
    
    // 主按鈕動畫用的狀態
    @State private var btnScale: CGFloat = 1.0
    @State private var btnRotation: Double = 0
    @State private var isAnimating = false
    
    // ✅ 用來控制「一顆一顆」出現
    @State private var showMenuItems: Bool = false
    
    // 外觀
    private let fabCircleSize: CGFloat = 60
    private let fabCircleBg = Color.white.opacity(0.14)
    private let pillBg = Color.white.opacity(0.12)
    private let pillStroke = Color.white.opacity(0.10)
    
    // ✅ 每顆之間的延遲（想更像“彈跳階梯”，調這裡）
    private let itemDelay: Double = 0.04
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            
            // 選單：展開才出現
            if fab.isExpanded {
                VStack(alignment: .trailing, spacing: 8) {
                    ForEach(Array(fab.actions.enumerated()), id: \.element.id) { index, item in
                        Button {
                            item.action()
                            collapseSequence()
                        } label: {
                            HStack(spacing: 8) {
                                Text(item.title)
                                    .font(.callout.weight(.semibold))
                                Image(systemName: item.systemImage)
                                    .font(.callout.weight(.semibold))
                            }
                            .foregroundStyle(.white.opacity(0.92))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(pillBg)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(pillStroke, lineWidth: 1))
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
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // 主按鈕
            Button {
                if fab.isExpanded {
                    collapseSequence()
                } else {
                    expandSequence()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white.opacity(0.95))
                    .frame(width: fabCircleSize, height: fabCircleSize)
                    .background(fabCircleBg)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
                    .scaleEffect(btnScale)
                    .rotationEffect(.degrees(btnRotation))
            }
            .buttonStyle(.plain)
            .disabled(isAnimating)
        }
    }
    
    // MARK: - 展開：先縮小 -> 旋轉放大成 X（同時開始逐顆彈出）
    private func expandSequence() {
        guard !isAnimating else { return }
        isAnimating = true
        
        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.05)) {
                btnScale = 0.72
            }
            try? await Task.sleep(nanoseconds: 80_000_000)
            
            // 先打開容器（讓列表存在），再讓每顆依序出現
            fab.isExpanded = true
            showMenuItems = false
            
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                btnRotation = 135
                btnScale = 1.28
            }
            
            // ✅ 觸發逐顆彈出
            showMenuItems = true
            
            try? await Task.sleep(nanoseconds: 70_000_000)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                btnScale = 1.0
            }
            
            try? await Task.sleep(nanoseconds: 120_000_000)
            isAnimating = false
        }
    }
    
    // MARK: - 收合：先縮小 -> 旋轉回 +（先逐顆收起，再關容器）
    private func collapseSequence() {
        guard !isAnimating else { return }
        isAnimating = true
        
        Task { @MainActor in
            // ✅ 先讓每顆依序收起（反向階梯）
            showMenuItems = false
            
            // 等最後一顆收完再關容器（動作數 * delay + 一點緩衝）
            let totalDelay = Double(max(fab.actions.count - 1, 0)) * itemDelay
            let waitForItems = UInt64((totalDelay + 0.04) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: waitForItems)
            
            withAnimation(.easeOut(duration: 0.05)) {
                btnScale = 0.72
            }
            try? await Task.sleep(nanoseconds: 80_000_000)
            
            fab.isExpanded = false
            withAnimation(.spring(response: 0.22, dampingFraction: 0.80)) {
                btnRotation = 0
                btnScale = 1.18
            }
            
            try? await Task.sleep(nanoseconds: 70_000_000)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                btnScale = 1.0
            }
            
            try? await Task.sleep(nanoseconds: 120_000_000)
            isAnimating = false
        }
    }
}
