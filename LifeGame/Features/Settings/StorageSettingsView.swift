import SwiftUI

struct StorageSettingsView: View {
    @Environment(StorageCoordinator.self) private var coordinator
    @Environment(StorageConfiguration.self) private var storageConfig

    @State private var showRestartAlert = false
    @State private var showICloudError = false

    private var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    var body: some View {
        Form {
            // MARK: - iCloud 帳號狀態
            Section {
                HStack {
                    Image(systemName: isICloudAvailable ? "checkmark.icloud.fill" : "xmark.icloud")
                        .foregroundStyle(isICloudAvailable ? .green : .red)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isICloudAvailable ? "已登入 iCloud" : "未登入 iCloud")
                            .font(.body.weight(.medium))
                        if !isICloudAvailable {
                            Text("請到「設定」→ 最上方 → 登入 Apple ID")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("帳號狀態")
            }

            // MARK: - 同步開關
            Section {
                Toggle(
                    "iCloud 同步",
                    isOn: Binding(
                        get: {
                            if let pending = storageConfig.pendingMode {
                                return pending == .iCloud
                            }
                            return storageConfig.currentMode == .iCloud
                        },
                        set: { enabled in
                            toggleMode(enabled)
                        }
                    )
                )
                .disabled(!isICloudAvailable && storageConfig.currentMode == .local)
            } header: {
                Text("儲存方式")
            } footer: {
                if let error = coordinator.switchError {
                    Label("上次切換失敗：\(error)", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if coordinator.hasPendingSwitch,
                          let pending = coordinator.pendingMode {
                    Text("將在下次啟動 App 時切換為\(pending == .iCloud ? " iCloud 同步" : "本機儲存")")
                        .foregroundStyle(.orange)
                } else {
                    switch storageConfig.currentMode {
                    case .local:
                        Text("資料僅儲存在本機裝置上")
                    case .iCloud:
                        Text("資料會自動同步到 iCloud，可在多台裝置間共享")
                    }
                }
            }

            if coordinator.hasPendingSwitch {
                Section {
                    Button("取消切換") {
                        coordinator.cancelPendingSwitch()
                    }
                    .foregroundStyle(.red)
                }
            }

            // MARK: - 說明
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("iCloud 同步使用你的 Apple ID", systemImage: "person.icloud")
                    Text("開啟 iCloud 同步後，資料會自動在你登入同一個 Apple ID 的所有裝置間同步，不需要額外登入。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("說明")
            }
        }
        .navigationTitle("儲存設定")
        .alert("需要重新啟動", isPresented: $showRestartAlert) {
            Button("好") {}
        } message: {
            Text("儲存方式將在下次開啟 App 時切換。請手動關閉並重新開啟 App。")
        }
        .alert("iCloud 不可用", isPresented: $showICloudError) {
            Button("確定") {}
        } message: {
            Text("請先在「設定」中登入 iCloud 帳號。")
        }
    }

    private func toggleMode(_ enableICloud: Bool) {
        let newMode: StorageMode = enableICloud ? .iCloud : .local

        if newMode == .iCloud {
            guard isICloudAvailable else {
                showICloudError = true
                return
            }
            // 手動開啟 iCloud，清除手動 local 標記
            UserDefaults.standard.removeObject(forKey: "lifegame.storage.manuallySetLocal")
        } else {
            // 使用者手動選擇 local，標記起來避免自動恢復覆蓋
            UserDefaults.standard.set(true, forKey: "lifegame.storage.manuallySetLocal")
        }

        coordinator.scheduleSwitch(to: newMode)
        showRestartAlert = true
    }
}

#Preview {
    NavigationStack {
        StorageSettingsView()
    }
}
