import SwiftUI
import Combine

// MARK: - 使用者角色

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case student
    case worker

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .student: return "學生"
        case .worker:  return "上班族"
        }
    }
}

// MARK: - 時段名稱 Store

/// 管理使用者角色與自訂時段名稱
/// - 預設角色：學生
/// - 每個時段根據角色有不同預設名稱
/// - 使用者可自訂覆蓋任何時段名稱
@MainActor
final class TimeSlotNameStore: ObservableObject {

    @Published var role: UserRole {
        didSet { if !isReloading { save() } }
    }

    /// 使用者自訂名稱（覆蓋角色預設）
    /// key = TimeSlot.rawValue, value = 自訂名稱
    @Published var customNames: [String: String] {
        didSet { if !isReloading { save() } }
    }

    private let key = "timeslot_names_v1"
    private var syncHelper: StoreSyncHelper?
    private var isReloading = false

    // MARK: - Codable 儲存結構
    private struct StoredData: Codable {
        var role: UserRole
        var customNames: [String: String]
    }

    init() {
        if let stored: StoredData = StorageManager.load(StoredData.self, forKey: key) {
            self.role = stored.role
            self.customNames = stored.customNames
        } else {
            self.role = .student
            self.customNames = [:]
        }
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    // MARK: - Cross-device Sync

    func reloadFromStorage() {
        isReloading = true
        defer { isReloading = false }
        if let stored: StoredData = StorageManager.load(StoredData.self, forKey: key) {
            role = stored.role
            customNames = stored.customNames
        }
    }

    // MARK: - Public API

    /// 取得時段的顯示名稱
    /// 優先使用自訂名稱，否則用角色預設
    func displayName(for slot: TimeSlot) -> String {
        if let custom = customNames[slot.rawValue], !custom.isEmpty {
            return custom
        }
        return slot.defaultName(for: role)
    }

    /// 設定自訂名稱（傳空字串 = 清除自訂，回歸角色預設）
    func setCustomName(_ name: String, for slot: TimeSlot) {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            customNames.removeValue(forKey: slot.rawValue)
        } else {
            customNames[slot.rawValue] = name
        }
    }

    /// 清除所有自訂名稱（回歸角色預設）
    func resetAllNames() {
        customNames = [:]
    }

    // MARK: - Persistence

    private func save() {
        let data = StoredData(role: role, customNames: customNames)
        StorageManager.save(data, forKey: key)
    }
}
