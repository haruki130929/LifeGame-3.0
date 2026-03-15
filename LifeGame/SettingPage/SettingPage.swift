// File: Settings/SettingsPage.swift
import SwiftUI

struct SettingsPage: View {
    @ObservedObject var store: EquipmentStore
    
    // ✅ SwiftData keys（原本的 AppStorage key 直接沿用）
    private let settleEnabledKey = "settleReminderEnabled_v1"
    private let settleHourKey = "settleReminderHour"
    private let settleMinuteKey = "settleReminderMinute"
    private let hourlyMoodEnabledKey = "hourlyMoodReminderEnabled_v1"
    
    // ✅ 改成 View 的狀態；實際持久化改走 StorageManager（SwiftData）
    @State private var settleReminderEnabled: Bool = false
    @State private var settleReminderHour: Int = 22
    @State private var settleReminderMinute: Int = 0
    @State private var hourlyMoodEnabled: Bool = false
    
    @State private var showTimePicker = false
    
    //@EnvironmentObject var theme: ThemeStore
    @EnvironmentObject var moodStore: MoodStore
    @ObservedObject var game: LifeGame
    @ObservedObject var calendarStore: CalendarStore
    @ObservedObject var calendarSettings: CalendarSettingsStore
    
    var body: some View {
        List {
            NavigationLink("能力值設定") {
                StatsSettingsView(game: game)
            }
            NavigationLink("裝備設定") { EquipmentSettingsView(store: store) }
            NavigationLink("行事曆") {
                CalendarHubView(
                    store: calendarStore,
                    settings: calendarSettings
                )
            }
            Section("外觀") {
                NavigationLink("外觀自訂") {
                    AppearanceSettingsView()
                }
            }
            Section("提醒") {
                Toggle("每小時提醒記錄心情", isOn: $hourlyMoodEnabled)
                    .onChange(of: hourlyMoodEnabled) { _, newValue in
                        // ✅ 先存設定（SwiftData）
                        StorageManager.save(newValue, forKey: hourlyMoodEnabledKey)
                        
                        if newValue {
                            NotificationManager.requestPermissionIfNeeded { granted in
                                DispatchQueue.main.async {
                                    if granted {
                                        NotificationManager.scheduleHourlyMoodReminder(minute: 0)
                                    } else {
                                        hourlyMoodEnabled = false
                                        StorageManager.save(false, forKey: hourlyMoodEnabledKey)
                                    }
                                }
                            }
                        } else {
                            NotificationManager.cancelHourlyMoodReminder()
                        }
                    }
                
                Toggle("一天結束結算提醒", isOn: $settleReminderEnabled)
                    .onChange(of: settleReminderEnabled) { _, newValue in
                        // ✅ 先存設定（SwiftData）
                        StorageManager.save(newValue, forKey: settleEnabledKey)
                        
                        if newValue {
                            NotificationManager.ensurePermissionThenScheduleDaily(
                                hour: settleReminderHour,
                                minute: settleReminderMinute
                            ) {
                                settleReminderEnabled = false
                                StorageManager.save(false, forKey: settleEnabledKey)
                            }
                        } else {
                            NotificationManager.cancelDailySettleReminder()
                        }
                    }
                
                Text("開啟後每天 \(String(format: "%02d:%02d", settleReminderHour, settleReminderMinute)) 提醒一次。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                Button {
                    showTimePicker = true
                } label: {
                    HStack {
                        Text("提醒時間")
                        Spacer()
                        Text(String(format: "%02d:%02d", settleReminderHour, settleReminderMinute))
                            .foregroundStyle(settleReminderEnabled ? .primary : .secondary)
                    }
                }
                .disabled(!settleReminderEnabled)
                .sheet(isPresented: $showTimePicker) {
                    NavigationStack {
                        Form {
                            DatePicker("提醒時間", selection: reminderTimeBinding, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                        }
                        .navigationTitle("提醒時間")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("完成") { showTimePicker = false }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("設定")
        .onAppear {
            loadReminderSettingsFromSwiftData()
        }
    }
    
    private func loadReminderSettingsFromSwiftData() {
        // ✅ 有存就用存的，沒有就維持預設值
        if let v: Bool = StorageManager.load(Bool.self, forKey: settleEnabledKey) {
            settleReminderEnabled = v
        }
        if let h: Int = StorageManager.load(Int.self, forKey: settleHourKey) {
            settleReminderHour = h
        }
        if let m: Int = StorageManager.load(Int.self, forKey: settleMinuteKey) {
            settleReminderMinute = m
        }
        if let v: Bool = StorageManager.load(Bool.self, forKey: hourlyMoodEnabledKey) {
            hourlyMoodEnabled = v
        }
        
        // （可選但建議）重開 app 時，如果開關是 on，就補排一次，避免系統清掉排程時你不知情
        if settleReminderEnabled {
            NotificationManager.ensurePermissionThenScheduleDaily(
                hour: settleReminderHour,
                minute: settleReminderMinute
            ) {
                settleReminderEnabled = false
                StorageManager.save(false, forKey: settleEnabledKey)
            }
        }
        
        if hourlyMoodEnabled {
            NotificationManager.requestPermissionIfNeeded { granted in
                DispatchQueue.main.async {
                    if granted {
                        NotificationManager.scheduleHourlyMoodReminder(minute: 0)
                    } else {
                        hourlyMoodEnabled = false
                        StorageManager.save(false, forKey: hourlyMoodEnabledKey)
                    }
                }
            }
        }
    }
    
    private var reminderTimeBinding: Binding<Date> {
        Binding<Date>(
            get: {
                var cal = Calendar.current
                cal.timeZone = TimeZone(identifier: "Asia/Taipei") ?? .current
                let now = Date()
                var comps = cal.dateComponents([.year, .month, .day], from: now)
                comps.hour = settleReminderHour
                comps.minute = settleReminderMinute
                return cal.date(from: comps) ?? now
            },
            set: { newValue in
                var cal = Calendar.current
                cal.timeZone = TimeZone(identifier: "Asia/Taipei") ?? .current
                let comps = cal.dateComponents([.hour, .minute], from: newValue)
                
                settleReminderHour = comps.hour ?? settleReminderHour
                settleReminderMinute = comps.minute ?? settleReminderMinute
                
                // ✅ 存到 SwiftData
                StorageManager.save(settleReminderHour, forKey: settleHourKey)
                StorageManager.save(settleReminderMinute, forKey: settleMinuteKey)
                
                if settleReminderEnabled {
                    NotificationManager.ensurePermissionThenScheduleDaily(
                        hour: settleReminderHour,
                        minute: settleReminderMinute
                    ) {
                        settleReminderEnabled = false
                        StorageManager.save(false, forKey: settleEnabledKey)
                    }
                }
            }
        )
    }
}

struct EquipmentSettingsView: View {
    @ObservedObject var store: EquipmentStore
    @State private var showAdd = false
    
    var body: some View {
        List {
            ForEach(store.items) { item in
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name).font(.headline)
                    ForEach(item.effects, id: \.self) { effect in
                        Text(effect.displayText).font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        if let idx = store.items.firstIndex(of: item) {
                            store.items.remove(at: idx)
                            store.save()
                        }
                    } label: { Image(systemName: "trash").accessibilityLabel("刪除") }
                }
            }
        }
        .navigationTitle("裝備設定")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus").accessibilityLabel("新增裝備") }
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack { AddEquipmentView(store: store) }
        }
    }
}

struct AddEquipmentView: View {
    @ObservedObject var store: EquipmentStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var slot: EquipSlot = .comfort
    @State private var mpMaxDelta: Int = 0
    @State private var weight: Int = 2
    
    @FocusState private var nameFocused: Bool
    
    var body: some View {
        Form {
            Section("基本資訊") {
                TextField("裝備名稱", text: $name)
                    .focused($nameFocused)
                
                Picker("部位", selection: $slot) {
                    ForEach(EquipSlot.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
            }
            
            Section("效果") {
                Stepper("MP 上限變化：\(mpMaxDelta)", value: $mpMaxDelta, in: -50...50, step: 5)
                Stepper("重量：\(weight)", value: $weight, in: 0...10, step: 1)
                
                Text("預覽：\(previewText)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("新增裝備")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                nameFocused = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("確定") {
                    save()
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private var previewText: String {
        var parts: [String] = []
        if mpMaxDelta != 0 { parts.append("MP上限 \(mpMaxDelta > 0 ? "+" : "")\(mpMaxDelta)") }
        parts.append("重量 +\(weight)")
        return parts.joined(separator: "，")
    }
    
    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        var effects: [EquipEffect] = []
        if mpMaxDelta != 0 { effects.append(.mpMax(mpMaxDelta)) }
        effects.append(.weight(weight))
        
        let item = EquipItem(slot: slot, name: trimmed, effects: effects)
        store.items.append(item)
        store.save()
    }
}
