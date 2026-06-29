import SwiftUI

/// 浮動的待辦水族箱面板：收合時是小把手，展開是水缸（魚游動 + 失衡提示 + 新增）。
struct AquariumPanelView: View {
    @EnvironmentObject private var aquarium: AquariumStore
    @EnvironmentObject private var theme: ThemeStore
    @StateObject private var tank = AquariumTank()

    @State private var showComposer = false
    @State private var composerType: FishType = .social
    @State private var selectedFish: UUID?

    private var panelWidth: CGFloat { AppLayout.isIPad ? 360 : 300 }
    private var tankHeight: CGFloat { AppLayout.isIPad ? 300 : 240 }

    var body: some View {
        Group {
            if aquarium.isExpanded {
                expandedPanel
                    .transition(.move(edge: .leading).combined(with: .opacity))
            } else {
                collapsedHandle
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .onChange(of: aquarium.tasks) { _, newTasks in
            tank.reconcile(with: newTasks)
        }
    }

    // MARK: - 收合：小把手

    private var collapsedHandle: some View {
        Button {
            setExpanded(true)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "fish")
                if !aquarium.tasks.isEmpty {
                    Text("\(aquarium.tasks.count)")
                        .font(.caption.weight(.semibold))
                }
                Image(systemName: "chevron.right")
                    .font(.caption2)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(theme.floatingButtonFill, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08)))
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }

    // MARK: - 展開：水缸面板

    private var expandedPanel: some View {
        VStack(spacing: 0) {
            header
            tankView
        }
        .frame(width: panelWidth)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        )
        .shadow(color: .black.opacity(0.14), radius: 14, y: 5)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button { setExpanded(false) } label: {
                Image(systemName: "chevron.down")
                    .font(.headline)
            }
            .buttonStyle(.plain)

            Text("待辦水族箱")
                .font(.subheadline.weight(.semibold))

            Spacer()

            Text("\(aquarium.tasks.count) 隻魚")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                composerType = .social
                showComposer = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .sheet(isPresented: $showComposer) {
            AquariumComposerView(initialType: composerType)
                .environmentObject(aquarium)
                .environmentObject(theme)
        }
    }

    private var tankView: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                AquariumPalette.waterColor(isDark: theme.isDark)

                ForEach(tank.sprites) { sprite in
                    FishView(type: sprite.type,
                             color: AquariumPalette.bodyColor(for: sprite.type, isDark: theme.isDark),
                             facingLeft: sprite.facingLeft)
                        .frame(width: 58 * sprite.scale, height: 40 * sprite.scale)
                        .position(sprite.pos)
                        .onTapGesture { selectedFish = sprite.id }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)))
                }

                if let tip = aquarium.imbalanceTip {
                    tipBanner(tip)
                }

                if let id = selectedFish, let task = aquarium.task(id) {
                    fishCallout(task)
                }
            }
            .onAppear {
                tank.bounds = geo.size
                tank.reconcile(with: aquarium.tasks)
                tank.start()
            }
            .onChange(of: geo.size) { _, newSize in
                tank.bounds = newSize
            }
            .onDisappear { tank.stop() }
        }
        .frame(height: tankHeight)
    }

    // MARK: - 失衡提示

    private func tipBanner(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(text)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.yellow.opacity(0.92), in: Capsule())
        .foregroundStyle(.black.opacity(0.82))
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    // MARK: - 點魚 → 任務名稱 + 完成

    private func fishCallout(_ task: AquariumTask) -> some View {
        ZStack {
            Color.black.opacity(0.04)
                .contentShape(Rectangle())
                .onTapGesture { selectedFish = nil }

            VStack(spacing: 10) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.center)
                HStack(spacing: 10) {
                    Button("關閉") { selectedFish = nil }
                        .buttonStyle(.bordered)
                    Button {
                        complete(task.id)
                    } label: {
                        Label("完成", systemImage: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func setExpanded(_ expanded: Bool) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            aquarium.isExpanded = expanded
        }
    }

    private func complete(_ id: UUID) {
        selectedFish = nil
        aquarium.complete(id)
    }
}
