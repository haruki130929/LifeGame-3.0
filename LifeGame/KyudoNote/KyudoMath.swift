import Foundation

enum KyudoMath {
    /// p: 0...1 相對座標
    static func distanceToCenter(x: Double, y: Double) -> Double {
        let dx = x - 0.5
        let dy = y - 0.5
        return (dx * dx + dy * dy).squareRoot()
    }
    
    static func isHit(_ shot: ShotPoint, hitRadius: Double) -> Bool {
        distanceToCenter(x: shot.x, y: shot.y) <= hitRadius
    }
    
    static func hitCount(shots: [ShotPoint], hitRadius: Double) -> Int {
        shots.filter { isHit($0, hitRadius: hitRadius) }.count
    }
    
    static func hitRatePercent(shots: [ShotPoint], hitRadius: Double) -> Int {
        guard !shots.isEmpty else { return 0 }
        let hits = Double(hitCount(shots: shots, hitRadius: hitRadius))
        let total = Double(shots.count)
        return Int((hits / total * 100.0).rounded())
    }
}
