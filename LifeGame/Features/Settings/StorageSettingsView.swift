import SwiftUI

struct StorageSettingsView: View {
    @Environment(StorageCoordinator.self) private var coordinator
    @Environment(StorageConfiguration.self) private var storageConfig

    @State private var showRestartAlert = false
    @State private var showICloudError = false

    var body: some View {
        Form {
            Section {
                Toggle(
                    "iCloud 同步",
                    isOn: Binding(
                        get: {
                            // 如果有 pending 切換，顯示 pending 的狀態
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
            } header: {
                Text("儲存方式")
            } footer: {
                if coordinator.hasPendingSwitch,
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
            guard FileManager.default.ubiquityIdentityToken != nil else {
                showICloudError = true
                return
            }
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
