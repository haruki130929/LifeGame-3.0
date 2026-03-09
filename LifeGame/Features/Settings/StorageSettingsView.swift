import SwiftUI

struct StorageSettingsView: View {
    @Environment(StorageCoordinator.self) private var coordinator
    @Environment(StorageConfiguration.self) private var storageConfig

    @State private var migrationError: StorageError?
    @State private var showError = false

    var body: some View {
        Form {
            Section {
                Toggle(
                    "iCloud 同步",
                    isOn: Binding(
                        get: { storageConfig.currentMode == .iCloud },
                        set: { enabled in
                            Task { await toggleMode(enabled) }
                        }
                    )
                )
                .disabled(coordinator.isMigrating)

                if coordinator.isMigrating {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("資料遷移中...")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("儲存方式")
            } footer: {
                switch storageConfig.currentMode {
                case .local:
                    Text("資料僅儲存在本機裝置上")
                case .iCloud:
                    Text("資料會自動同步到 iCloud，可在多台裝置間共享")
                }
            }
        }
        .navigationTitle("儲存設定")
        .alert("遷移失敗", isPresented: $showError) {
            Button("確定") { migrationError = nil }
        } message: {
            Text(migrationError?.localizedDescription ?? "發生未知錯誤")
        }
    }

    private func toggleMode(_ enableICloud: Bool) async {
        let newMode: StorageMode = enableICloud ? .iCloud : .local
        do {
            try await coordinator.switchMode(to: newMode)
        } catch let error as StorageError {
            migrationError = error
            showError = true
        } catch {
            migrationError = .migrationFailed(underlying: error)
            showError = true
        }
    }
}

#Preview {
    NavigationStack {
        StorageSettingsView()
    }
}
