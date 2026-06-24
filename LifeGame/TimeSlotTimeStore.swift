import SwiftUI
import Combine

// MARK: - 時段時間 Store

/// 管理每個時段的「開始時間」（以當天分鐘數 0–1439 儲存）
/// - 打開 App 時依目前時間自動選中所屬時段
/// - 使用者可在設定中自訂每個時段的開始時間
/// - 跨裝置同步：透過 StoreSyncHelper 在前景 / CloudKit 變更時重載
@MainActor
final class TimeSlotTimeStore: ObservableObject {

    /// 每個時段的開始時間
    /// key = TimeSlot.rawValue, value = 當天分鐘數（0–1439，例如 08:30 = 510）
    @Published var startMinutes: [String: Int] {
        didSet { if !isReloading { save() } }
    }

    private let key = "timeslot_times_v1"
    private var syncHelper: StoreSyncHelper?
    private var isReloading = false

    /// 預設開始時間（與舊版 TimeSlot.current 的硬編界線一致）
    static let defaultStartMinutes: [String: Int] = [
        TimeSlot.beforeLeave.rawValue:    4 * 60,   // 04:00 出門前/上班前
        TimeSlot.morning.rawValue:        8 * 60,   // 08:00 上午
        TimeSlot.earlyAfternoon.rawValue: 12 * 60,  // 12:00 下午三點前
        TimeSlot.beforeEnd.rawValue:      15 * 60,  // 15:00 下課前/下班前
        TimeSlot.bedtime.rawValue:        18 * 60,  // 18:00 睡前
    ]

    // MARK: - Codable 儲存結構
    private struct StoredData: Codable {
        var startMinutes: [String: Int]
    }

    init() {
        if let stored: StoredData = StorageManager.load(StoredData.self, forKey: key) {
            self.startMinutes = stored.startMinutes
        } else {
            self.startMinutes = Self.defaultStartMinutes
        }
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    // MARK: - Cross-device Sync

    func reloadFromStorage() {
        isReloading = true
        defer { isReloading = false }
        if let stored: StoredData = StorageManager.load(StoredData.self, forKey: key) {
            startMinutes = stored.startMinutes
        }
    }

    // MARK: - Public API

    /// 取得時段的開始時間（當天分鐘數）
    func startMinute(for slot: TimeSlot) -> Int {
        startMinutes[slot.rawValue]
            ?? Self.defaultStartMinutes[slot.rawValue]
            ?? 0
    }

    /// 以 Date 形式取得開始時間（供 DatePicker 綁定，只用到時/分）
    func startTime(for slot: TimeSlot, calendar: Calendar = .current) -> Date {
        let minutes = startMinute(for: slot)
        return calendar.date(
            bySettingHour: minutes / 60,
            minute: minutes % 60,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    /// 設定時段開始時間（只取時/分）
    func setStartTime(_ date: Date, for slot: TimeSlot, calendar: Calendar = .current) {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        startMinutes[slot.rawValue] = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    /// 回復所有時段為預設時間
    func resetAll() {
        startMinutes = Self.defaultStartMinutes
    }

    // MARK: - 依目前時間判斷時段

    /// 依目前時間回傳所屬時段（打開 App 自動選時段用）。
    /// 規則：每個時段從它的開始時間起算，到下一個時段開始為止；
    /// 取「開始時間 ≤ 現在」中最接近現在的時段。
    /// 若現在比所有開始時間都早（凌晨），則屬於最晚開始的時段（睡前跨夜到隔天清晨）。
    func currentSlot(at date: Date = Date(), calendar: Calendar = .current) -> TimeSlot {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        let now = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

        let sorted = TimeSlot.allCases
            .map { (slot: $0, start: startMinute(for: $0)) }
            .sorted { $0.start < $1.start }

        guard let lastSlot = sorted.last?.slot else { return .beforeLeave }
        var active = lastSlot   // 凌晨跨夜 → 最晚開始的時段
        for entry in sorted where entry.start <= now {
            active = entry.slot
        }
        return active
    }

    // MARK: - Persistence

    private func save() {
        StorageManager.save(StoredData(startMinutes: startMinutes), forKey: key)
    }
}
