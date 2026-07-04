import Foundation
import Combine
import EventKit
import SwiftUI
import UIKit

@MainActor
final class CalendarStore: ObservableObject {
    private static let storageKey = "calendar_events_v1"
    
    @Published var events: [CalendarEvent] = [] {
        didSet { if !isReloading { save() } }
    }

    private let eventStore = EKEventStore()
    private var syncHelper: StoreSyncHelper?
    private var isReloading = false
    
    init() {
        load()
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
        setupAppleCalendarAutoSync()
    }

    func reloadFromStorage() {
        isReloading = true
        defer { isReloading = false }
        if let saved: [CalendarEvent] = StorageManager.load([CalendarEvent].self, forKey: Self.storageKey) {
            events = saved
        }
    }
    
    func requestAccessIfNeeded() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            debugLog("行事曆授權失敗：\(error)")
            return false
        }
    }
    
    func add(title: String, start: Date, end: Date, colorHex: String = "33A6B8",
             frequency: RecurringFrequency = .none, repeatCount: Int = 12) async {
        let granted = await requestAccessIfNeeded()

        if frequency != .none {
            // 重複事件
            let groupId = UUID()
            let cal = Calendar.current
            let duration = end.timeIntervalSince(start)

            // EKRecurrenceFrequency 對應
            let ekFrequency: EKRecurrenceFrequency
            let interval: Int
            switch frequency {
            case .daily:    ekFrequency = .daily;  interval = 1
            case .weekly:   ekFrequency = .weekly; interval = 1
            case .biweekly: ekFrequency = .weekly; interval = 2
            case .monthly:  ekFrequency = .monthly; interval = 1
            case .none:     ekFrequency = .daily;  interval = 1 // 不會執行到
            }

            // Apple 行事曆
            var appleEventIdentifier: String? = nil
            if granted {
                do {
                    let ekEvent = EKEvent(eventStore: eventStore)
                    ekEvent.title = title
                    ekEvent.startDate = start
                    ekEvent.endDate = end
                    ekEvent.calendar = eventStore.defaultCalendarForNewEvents
                    ekEvent.recurrenceRules = [EKRecurrenceRule(
                        recurrenceWith: ekFrequency,
                        interval: interval,
                        end: EKRecurrenceEnd(occurrenceCount: repeatCount)
                    )]
                    try eventStore.save(ekEvent, span: .thisEvent)
                    appleEventIdentifier = ekEvent.eventIdentifier
                } catch {
                    debugLog("寫入 Apple 週期行事曆失敗：\(error)")
                }
            }

            // App 內部：建立個別事件
            for i in 0..<repeatCount {
                let offsetStart: Date
                switch frequency {
                case .daily:    offsetStart = cal.date(byAdding: .day, value: i, to: start)!
                case .weekly:   offsetStart = cal.date(byAdding: .weekOfYear, value: i, to: start)!
                case .biweekly: offsetStart = cal.date(byAdding: .weekOfYear, value: i * 2, to: start)!
                case .monthly:  offsetStart = cal.date(byAdding: .month, value: i, to: start)!
                case .none:     offsetStart = start
                }
                let offsetEnd = offsetStart.addingTimeInterval(duration)
                let e = CalendarEvent(
                    title: title,
                    start: offsetStart,
                    end: offsetEnd,
                    colorHex: colorHex,
                    isWeeklyRecurring: true,
                    recurringGroupId: groupId,
                    appleEventIdentifier: i == 0 ? appleEventIdentifier : nil,
                    isFromAppleCalendar: false   // 手動建立：保留使用者選的顏色，不被 Apple 顏色覆蓋
                )
                events.insert(e, at: 0)
            }
        } else {
            // 單次事件
            var appleEventIdentifier: String? = nil
            if granted {
                do {
                    let ekEvent = EKEvent(eventStore: eventStore)
                    ekEvent.title = title
                    ekEvent.startDate = start
                    ekEvent.endDate = end
                    ekEvent.calendar = eventStore.defaultCalendarForNewEvents
                    try eventStore.save(ekEvent, span: .thisEvent)
                    appleEventIdentifier = ekEvent.eventIdentifier
                } catch {
                    debugLog("寫入 Apple 行事曆失敗：\(error)")
                }
            }

            let e = CalendarEvent(
                title: title,
                start: start,
                end: end,
                colorHex: colorHex,
                appleEventIdentifier: appleEventIdentifier,
                isFromAppleCalendar: false   // 手動建立：保留使用者選的顏色，不被 Apple 顏色覆蓋
            )
            events.insert(e, at: 0)
        }
    }

    /// 刪除整組週期事件
    func deleteRecurringGroup(_ groupId: UUID) {
        let groupEvents = events.filter { $0.recurringGroupId == groupId }
        for item in groupEvents {
            if let appleID = item.appleEventIdentifier,
               let ekEvent = eventStore.event(withIdentifier: appleID) {
                do {
                    try eventStore.remove(ekEvent, span: .futureEvents)
                } catch {
                    debugLog("刪除 Apple 週期事件失敗：\(error)")
                }
            }
        }
        events.removeAll { $0.recurringGroupId == groupId }
    }
    
    func delete(at offsets: IndexSet) {
        let deletingEvents = offsets.map { events[$0] }
        
        for item in deletingEvents {
            if let appleID = item.appleEventIdentifier,
               let ekEvent = eventStore.event(withIdentifier: appleID) {
                do {
                    try eventStore.remove(ekEvent, span: .thisEvent)
                } catch {
                    debugLog("刪除 Apple 行事曆事件失敗：\(error)")
                }
            }
        }
        
        events.remove(atOffsets: offsets)
    }
    
    func events(on day: Date, calendar: Calendar) -> [CalendarEvent] {
        events
            .filter { calendar.isDate($0.start, inSameDayAs: day) }
            .sorted { $0.start < $1.start }
    }
    
    func events(inWeekContaining anchor: Date, calendar: Calendar) -> [CalendarEvent] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: anchor) else { return [] }
        
        return events
            .filter { $0.start >= interval.start && $0.start < interval.end }
            .sorted { $0.start < $1.start }
    }
    
    func update(_ event: CalendarEvent) {
        guard let idx = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[idx] = event
    }

    // MARK: - 同步 Apple 行事曆

    /// 從 Apple 行事曆匯入指定範圍的事件
    @Published var lastSyncDate: Date?
    @Published var syncedCount: Int = 0

    /// 去重用的複合鍵：同一個重複行程的多個日期共用同一個 eventIdentifier，
    /// 用「ID + 開始時間」才能把每個日期當成獨立事件，避免漏匯。
    private static func occurrenceKey(_ id: String, _ start: Date) -> String {
        "\(id)|\(Int(start.timeIntervalSince1970))"
    }

    /// 把 Apple 行事曆的顏色（CGColor）轉成 "RRGGBB" 十六進位字串
    private static func hexString(from cgColor: CGColor) -> String? {
        let ui = UIColor(cgColor: cgColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if !ui.getRed(&r, green: &g, blue: &b, alpha: &a) {
            // 少數灰階色空間：用白點補上
            var w: CGFloat = 0
            guard ui.getWhite(&w, alpha: &a) else { return nil }
            r = w; g = w; b = w
        }
        func channel(_ v: CGFloat) -> Int { Int((max(0, min(1, v)) * 255).rounded()) }
        return String(format: "%02X%02X%02X", channel(r), channel(g), channel(b))
    }

    /// 匯入指定 [start, end] 範圍的 Apple 行事曆事件。
    /// 回傳匯入筆數；**回傳 -1 代表權限被拒**。
    func syncFromAppleCalendar(start: Date, end: Date) async -> Int {
        let granted = await requestAccessIfNeeded()
        guard granted else { return -1 }

        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)

        // 已存在的事件（ID + 開始時間），避免重複匯入；逐筆加入避免同批重複
        var seen = Set(events.compactMap { e -> String? in
            guard let id = e.appleEventIdentifier else { return nil }
            return Self.occurrenceKey(id, e.start)
        })

        var newEvents: [CalendarEvent] = []
        var colorByKey: [String: String] = [:]   // occurrenceKey → Apple 行事曆目前的顏色
        for ek in ekEvents {
            guard let identifier = ek.eventIdentifier, let ekStart = ek.startDate else { continue }
            let key = Self.occurrenceKey(identifier, ekStart)
            // 用 Apple 行事曆（該事件所屬日曆）的顏色上色；取不到才退回系統灰
            let hex = ek.calendar?.cgColor.flatMap { Self.hexString(from: $0) } ?? "8E8E93"
            colorByKey[key] = hex
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            newEvents.append(CalendarEvent(
                title: ek.title ?? "（無標題）",
                start: ekStart,
                end: ek.endDate ?? ekStart,
                colorHex: hex,
                appleEventIdentifier: identifier,
                isFromAppleCalendar: true
            ))
        }

        // 既有的「Apple 匯入」事件：跟著 Apple 行事曆「目前的顏色」更新
        //（含 Apple 端改過色、以及舊版用系統灰匯入的）。手動建立的事件不動，保留自選顏色。
        var working = events
        var changed = false
        for idx in working.indices {
            // 在 Apple 行事曆裡（有 appleEventIdentifier）、且不是「明確標記為手動」的，就跟著 Apple 顏色更新。
            // 舊版匯入的事件旗標是 nil（nil != false 成立）→ 也會被納入並順手補標記。
            let isImported = working[idx].appleEventIdentifier != nil && working[idx].isFromAppleCalendar != false
            guard isImported, let appleID = working[idx].appleEventIdentifier else { continue }
            let key = Self.occurrenceKey(appleID, working[idx].start)
            guard let hex = colorByKey[key] else { continue }   // 不在本次同步範圍的略過
            if working[idx].colorHex != hex {
                working[idx].colorHex = hex
                changed = true
            }
            if working[idx].isFromAppleCalendar != true {
                working[idx].isFromAppleCalendar = true   // 順手標記，之後就走旗標
                changed = true
            }
        }
        if !newEvents.isEmpty { working.append(contentsOf: newEvents); changed = true }

        // 刪除偵測：Apple 匯入的事件，若落在本次同步範圍內、但 Apple 那邊已經沒有這筆 → 移除。
        // colorByKey 收錄了本次抓到的「所有」Apple 事件 occurrenceKey；不在裡面＝已被 Apple 刪除。
        // 只動「Apple 匯入」的（isFromAppleCalendar != false 且有 appleEventIdentifier）；
        // 手動在 App 建立的事件不受影響。範圍外的不判斷（本次沒抓，無從得知）。
        let beforeCount = working.count
        working.removeAll { e in
            guard let appleID = e.appleEventIdentifier, e.isFromAppleCalendar != false else { return false }
            guard e.start >= start, e.start <= end else { return false }
            return colorByKey[Self.occurrenceKey(appleID, e.start)] == nil
        }
        let removedCount = beforeCount - working.count
        if removedCount > 0 { changed = true }

        if changed { events = working }   // 一次寫入，避免逐筆存檔

        let importCount = newEvents.count

        lastSyncDate = Date()
        syncedCount = importCount
        debugLog("✅ Apple 行事曆同步完成，匯入 \(importCount) 筆、移除 \(removedCount) 筆已刪除（範圍 \(start)～\(end)）")
        return importCount
    }
    
    // MARK: - 自動同步 Apple 行事曆

    static let autoSyncKey = "calendar.autoSyncAppleEnabled"
    private static let lastAutoSyncKey = "calendar.lastAutoAppleSync"

    private func setupAppleCalendarAutoSync() {
        // 系統行事曆有變動 → 立即同步
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: eventStore, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.autoSyncIfEnabled(force: true) }
        }
        // App 回到前景 → 同步（有節流）
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.autoSyncIfEnabled() }
        }
        autoSyncIfEnabled()   // 啟動時也試一次
    }

    /// 已開啟自動同步、且已有完整權限時，匯入近期 Apple 行事曆（**不會跳權限提示**）。
    func autoSyncIfEnabled(force: Bool = false) {
        guard UserDefaults.standard.bool(forKey: Self.autoSyncKey) else { return }
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return }

        // 節流：前景觸發 30 分鐘內不重複；行事曆變動（force）略過節流
        if !force {
            let last = UserDefaults.standard.double(forKey: Self.lastAutoSyncKey)
            if Date().timeIntervalSince1970 - last < 1800 { return }
        }
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.lastAutoSyncKey)

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .month, value: -1, to: today) ?? today
        let end = cal.date(byAdding: .month, value: 3, to: today) ?? today
        Task { _ = await syncFromAppleCalendar(start: start, end: end) }
    }

    private func save() {
        StorageManager.save(events, forKey: Self.storageKey)
    }
    
    private func load() {
        if let saved: [CalendarEvent] = StorageManager.load([CalendarEvent].self, forKey: Self.storageKey) {
            events = saved
        }
    }
}
