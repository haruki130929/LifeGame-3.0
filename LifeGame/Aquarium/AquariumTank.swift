import SwiftUI
import Combine

/// 一隻魚的「畫面狀態」（暫時、不持久化、不同步）
struct FishSprite: Identifiable {
    let id: UUID          // == AquariumTask.id
    let type: FishType
    var pos: CGPoint
    var vel: CGVector
    var scale: CGFloat

    var facingLeft: Bool { vel.dx < 0 }
}

/// 水缸動態引擎：以 60fps Timer 驅動魚群游動（仿 FabButton.startScrollTimer 慣例）。
/// 與 AquariumStore 分離 —— 任務資料不會因為每幀更新而重繪。
@MainActor
final class AquariumTank: ObservableObject {

    @Published private(set) var sprites: [FishSprite] = []

    /// 水箱可游動範圍（由 view 的 GeometryReader 設定）
    var bounds: CGSize = .zero {
        didSet { if oldValue != bounds { clampAll() } }
    }

    /// 最多顯示幾隻魚（超過只計數，不再生成新魚）
    static let maxFish = 24

    private static let baseWidth: CGFloat = 58
    private static let baseHeight: CGFloat = 40

    private var timer: Timer?
    private var isVisible = false

    // MARK: - Lifecycle

    /// 水缸是否顯示中（展開）。只有「可見 且 有魚」時才跑 60fps 計時器。
    func setVisible(_ visible: Bool) {
        isVisible = visible
        updateTimer()
    }

    private func startTimer() {
        guard timer == nil else { return }
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.step() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// 沒魚或收合時完全不轉 —— 避免空轉 60fps 一直 ping 主執行緒（收合動畫才會更順）
    private func updateTimer() {
        if isVisible && !sprites.isEmpty {
            startTimer()
        } else {
            stopTimer()
        }
    }

    // MARK: - Reconcile

    /// 依任務清單同步魚群：新增缺少的、移除已完成的（魚游走）、重算縮放。
    func reconcile(with tasks: [AquariumTask]) {
        let capped = Array(tasks.prefix(Self.maxFish))
        let wantedIDs = Set(capped.map(\.id))

        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            // 移除：已完成 / 超出上限
            sprites.removeAll { !wantedIDs.contains($0.id) }
            // 新增缺少的
            let existing = Set(sprites.map(\.id))
            for task in capped where !existing.contains(task.id) {
                sprites.append(makeSprite(for: task))
            }
            // 數量越多每隻越小
            let s = scaleForCount(sprites.count)
            for i in sprites.indices { sprites[i].scale = s }
        }
        updateTimer()
    }

    // MARK: - Private

    private func scaleForCount(_ count: Int) -> CGFloat {
        let ratio = CGFloat(min(count, Self.maxFish)) / CGFloat(Self.maxFish)
        return max(0.6, 1.0 - ratio * 0.35)
    }

    private func makeSprite(for task: AquariumTask) -> FishSprite {
        let w = max(bounds.width, 240)
        let h = max(bounds.height, 200)
        let pos = CGPoint(x: CGFloat.random(in: 40...(w - 40)),
                          y: CGFloat.random(in: 40...(h - 40)))
        let speed = CGFloat.random(in: 24...46)        // 點／秒
        let angle = CGFloat.random(in: 0 ..< (2 * .pi))
        let vel = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed * 0.5)
        return FishSprite(id: task.id, type: task.type, pos: pos, vel: vel,
                          scale: scaleForCount(sprites.count + 1))
    }

    /// 每幀更新所有魚的位置（撞牆反彈、偶爾轉向）。整批一次性指派，避免每隻各觸發一次發佈。
    private func step() {
        guard !sprites.isEmpty, bounds.width > 0, bounds.height > 0 else { return }
        let dt: CGFloat = 1.0 / 60.0
        var updated = sprites
        for i in updated.indices {
            let hw = Self.baseWidth / 2 * updated[i].scale
            let hh = Self.baseHeight / 2 * updated[i].scale
            var p = updated[i].pos
            var v = updated[i].vel
            p.x += v.dx * dt
            p.y += v.dy * dt
            if p.x < hw { p.x = hw; v.dx = abs(v.dx) }
            if p.x > bounds.width - hw { p.x = bounds.width - hw; v.dx = -abs(v.dx) }
            if p.y < hh { p.y = hh; v.dy = abs(v.dy) }
            if p.y > bounds.height - hh { p.y = bounds.height - hh; v.dy = -abs(v.dy) }
            // 偶爾改變垂直方向，游起來更自然
            if CGFloat.random(in: 0...1) < 0.01 {
                v.dy = CGFloat.random(in: -22...22)
            }
            updated[i].pos = p
            updated[i].vel = v
        }
        sprites = updated
    }

    private func clampAll() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        var updated = sprites
        for i in updated.indices {
            updated[i].pos.x = min(max(updated[i].pos.x, 30), max(bounds.width - 30, 30))
            updated[i].pos.y = min(max(updated[i].pos.y, 30), max(bounds.height - 30, 30))
        }
        sprites = updated
    }
}
