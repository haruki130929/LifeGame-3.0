import SwiftUI
import Combine

@MainActor
final class ScheduleStore: ObservableObject {
    
    private let storageKey = "schedule_hourly_titles_v1"
    private var syncHelper: StoreSyncHelper?
    private var isReloading = false

    /// 24 格：第 0 格代表 0:00～1:00，第 8 格代表 8:00～9:00
    @Published var hourlyTitles: [String] = Array(repeating: "", count: 24) {
        didSet { if !isReloading { save() } }
    }

    init() {
        load()
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    func reloadFromStorage() {
        isReloading = true
        defer { isReloading = false }
        if let saved: [String] = StorageManager.load([String].self, forKey: storageKey),
           saved.count == 24 {
            hourlyTitles = saved
        }
    }
    
    var blocks: [ScheduleBlock] {
        .blocks(from: hourlyTitles)
    }
    
    // MARK: - Persistence (SwiftData via StorageManager)
    
    private func save() {
        StorageManager.save(hourlyTitles, forKey: storageKey)
    }
    
    private func load() {
        if let saved: [String] = StorageManager.load([String].self, forKey: storageKey),
           saved.count == 24 {
            hourlyTitles = saved
        } else {
            hourlyTitles = Array(repeating: "", count: 24)
        }
    }
}
