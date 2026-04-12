import SwiftUI

struct CalendarSettingsView: View {
    @ObservedObject var settings: CalendarSettingsStore
    @EnvironmentObject var calendarStore: CalendarStore
    @State private var showAddPreset = false
    @State private var newPresetHex = "33A6B8"
    @State private var newPresetName = ""
    @State private var isSyncing = false
    @State private var syncResult: String?

    var body: some View {
        Form {
            Section {
                Picker("一週起始日", selection: $settings.firstWeekday) {
                    Text("週日").tag(1)
                    Text("週一").tag(2)
                }
            } header: {
                Text("顯示")
            }

            Section {
                Button {
                    isSyncing = true
                    syncResult = nil
                    Task {
                        let count = await calendarStore.syncFromAppleCalendar()
                        isSyncing = false
                        syncResult = count > 0 ? "已匯入 \(count) 筆行程" : "沒有新的行程"
                    }
                } label: {
                    HStack {
                        Label("同步 Apple 行事曆", systemImage: "arrow.triangle.2.circlepath")
                        Spacer()
                        if isSyncing {
                            ProgressView()
                        }
                    }
                }
                .disabled(isSyncing)
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("從 Apple 行事曆匯入未來 3 個月的行程")
                    if let result = syncResult {
                        Text(result)
                            .foregroundStyle(.green)
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
}
