import SwiftUI

struct CalendarSettingsView: View {
    @ObservedObject var settings: CalendarSettingsStore
    @EnvironmentObject var calendarStore: CalendarStore
    @State private var showAddPreset = false
    @State private var newPresetHex = "33A6B8"
    @State private var newPresetName = ""
    @State private var isSyncing = false
    @State private var syncResult: String?
    @State private var resultIsError = false
    @State private var importRange: CalendarImportRange = .past3MNext1Y
    @AppStorage(CalendarStore.autoSyncKey) private var autoSyncEnabled = false

    var body: some View {
        Form {
            Section {
                Picker("一週起始日", selection: $settings.firstWeekday) {
                    Text("週日").tag(1)
                    Text("週一").tag(2)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("行程字級", systemImage: "textformat.size")
                        Spacer()
                        Text("\(Int(settings.eventFontScale * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $settings.eventFontScale, in: 1.0...1.8, step: 0.05)
                    // 即時範例
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: "7F77DD") ?? .purple)
                            .frame(width: CGFloat(settings.eventFontScale) * 7,
                                   height: CGFloat(settings.eventFontScale) * 7)
                        Text("範例行程")
                            .font(.system(size: CGFloat(settings.eventFontScale) * 13))
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background((Color(hex: "7F77DD") ?? .purple).opacity(0.18),
                                in: RoundedRectangle(cornerRadius: 4))
                }
            } header: {
                Text("顯示")
            } footer: {
                Text("「行程字級」會調整功能頁月曆上每天行程名稱的大小。")
            }

            Section {
                Toggle(isOn: $autoSyncEnabled) {
                    Label("自動同步", systemImage: "arrow.triangle.2.circlepath.circle")
                }
                .onChange(of: autoSyncEnabled) { _, on in
                    if on { runImport() }   // 開啟時立刻同步一次（含權限請求）
                }

                Picker(selection: $importRange) {
                    ForEach(CalendarImportRange.allCases) { r in
                        Text(r.rawValue).tag(r)
                    }
                } label: {
                    Label("匯入範圍", systemImage: "calendar.badge.clock")
                }

                Button(action: runImport) {
                    HStack {
                        Label("立即同步 Apple 行事曆", systemImage: "arrow.triangle.2.circlepath")
                        Spacer()
                        if isSyncing {
                            ProgressView()
                        }
                    }
                }
                .disabled(isSyncing)
            } header: {
                Text("Apple 行事曆")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("開啟「自動同步」後，App 回到前景或行事曆有變動時會自動匯入新行程，不用手動按。重複的不會再匯入。")
                    if let result = syncResult {
                        Text(result)
                            .foregroundStyle(resultIsError ? .orange : .green)
                    }
                    if let lastSync = calendarStore.lastSyncDate {
                        Text("上次同步：\(lastSync.formatted(date: .abbreviated, time: .shortened))")
                    }
                }
            }

            Section {
                ForEach(settings.colorPresets) { preset in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: preset.colorHex))
                            .frame(width: 24, height: 24)
                        Text(preset.name)
                        Spacer()
                        Text(ColorPalette.name(for: preset.colorHex) ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    settings.colorPresets.remove(atOffsets: offsets)
                }

                Button {
                    showAddPreset = true
                } label: {
                    Label("新增顏色行程", systemImage: "plus")
                }
            } header: {
                Text("行程代表顏色")
            } footer: {
                Text("設定顏色對應的行程名稱，新增行程時選擇顏色會自動帶入名稱")
            }
        }
        .navigationTitle("行事曆設定")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddPreset) {
            NavigationStack {
                Form {
                    Section("行程名稱") {
                        TextField("例如：上課、運動", text: $newPresetName)
                    }
                    Section("選擇顏色") {
                        CompactPaletteColorPicker(selectedHex: $newPresetHex)
                    }
                }
                .navigationTitle("新增顏色行程")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { showAddPreset = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("加入") {
                            let name = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !name.isEmpty else { return }
                            settings.colorPresets.append(EventColorPreset(colorHex: newPresetHex, name: name))
                            newPresetName = ""
                            newPresetHex = "33A6B8"
                            showAddPreset = false
                        }
                        .disabled(newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }

    private func runImport() {
        isSyncing = true
        syncResult = nil
        let (start, end) = importRange.bounds()
        Task {
            let count = await calendarStore.syncFromAppleCalendar(start: start, end: end)
            isSyncing = false
            if count < 0 {
                resultIsError = true
                syncResult = "需要行事曆權限：請到「設定 → LifeGame → 行事曆」開啟"
            } else {
                resultIsError = false
                syncResult = count > 0 ? "已匯入 \(count) 筆行程" : "沒有新的行程"
            }
        }
    }
}

// MARK: - 匯入範圍

enum CalendarImportRange: String, CaseIterable, Identifiable {
    case next3M       = "未來 3 個月"
    case next1Y       = "未來 1 年"
    case past3MNext1Y = "過去 3 個月 ～ 未來 1 年"
    case past1YNext1Y = "過去 1 年 ～ 未來 1 年"

    var id: String { rawValue }

    func bounds() -> (start: Date, end: Date) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        func add(_ comp: Calendar.Component, _ value: Int) -> Date {
            cal.date(byAdding: comp, value: value, to: today) ?? today
        }
        switch self {
        case .next3M:       return (today, add(.month, 3))
        case .next1Y:       return (today, add(.year, 1))
        case .past3MNext1Y: return (add(.month, -3), add(.year, 1))
        case .past1YNext1Y: return (add(.year, -1), add(.year, 1))
        }
    }
}
