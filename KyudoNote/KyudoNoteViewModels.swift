import SwiftUI

final class KyudoNoteViewModel: ObservableObject {
    @Published var note = KyudoNote()
    
    // 靶面判定：距離中心 r <= 1 算「靶內」
    // 之後要改成「只算某圈」就改這個 threshold
    private let hitThreshold: CGFloat = 1.0
    
    func addHit(normalizedX: CGFloat, normalizedY: CGFloat) {
        let clampedX = max(-1, min(1, normalizedX))
        let clampedY = max(-1, min(1, normalizedY))
        note.hits.append(KyudoHit(x: clampedX, y: clampedY))
    }
    
    func removeLastHit() {
        guard !note.hits.isEmpty else { return }
        note.hits.removeLast()
    }
    
    func clearHits() {
        note.hits.removeAll()
    }
    
    var totalShots: Int { note.hits.count }
    
    var hitsInsideTargetCount: Int {
        note.hits.filter { isInsideTarget($0) }.count
    }
    
    var hitRateText: String {
        let total = totalShots
        guard total > 0 else { return "—" }
        let rate = Double(hitsInsideTargetCount) / Double(total) * 100.0
        return String(format: "%.1f%%", rate)
    }
    
    private func isInsideTarget(_ hit: KyudoHit) -> Bool {
        let r = sqrt(hit.x * hit.x + hit.y * hit.y)
        return r <= hitThreshold
    }
}
