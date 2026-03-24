import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BackupSettingsView: View {

    @Environment(StorageCoordinator.self) private var coordinator
    @Environment(StorageConfiguration.self) private var storageConfig

    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false

    @State private var showFileImporter = false
    @State private var showImportConfirm = false
    @State private var pendingImportURL: URL?

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    @State private var isProcessing = false

    var body: some View {
        Form {
            iCloudSection
            exportSection
            importSection
        }
        .navigationTitle("資料備份")
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleFileImporterResult(result)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert("確認匯入", isPresented: $showImportConfirm) {
            Button("取消", role: .cancel) {
                pendingImportURL = nil
            }
            Button("匯入", role: .destructive) {
                if let url = pendingImportURL {
                    performImport(from: url)
                }
            }
        } message: {
            Text("匯入會覆蓋現有的相同資料。建議先匯出目前的資料作為備份。\n\n匯入完成後請重新啟動 App。")
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .disabled(isProcessing)
    }
}

// MARK: - Sections

private extension BackupSettingsView {

    var iCloudSection: some View {
        Section {
            HStack {
                Label("iCloud 同步", systemImage: "icloud.fill")
                Spacer()
                Text(storageConfig.currentMode == .iCloud ? "已開啟" : "未開啟")
                    .foregroundStyle(.secondary)
            }

            if storageConfig.currentMode == .iCloud {
                Text("你的資料會自動透過 iCloud 同步。重新安裝 App 後，登入相同 Apple ID 即可恢復。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                NavigationLink("前往儲存設定開啟") {
                    StorageSettingsView()
                }
                .font(.subheadline)
            }
        } header: {
            Text("自動備份")
        } footer: {
            if storageConfig.currentMode != .iCloud {
                Text("開啟 iCloud 同步後，刪除 App 重新安裝也不會遺失資料")
            }
        }
    }

    var exportSection: some View {
        Section {
            Button {
                performExport()
            } label: {
                HStack {
                    Label("匯出資料", systemImage: "square.and.arrow.up")
                    Spacer()
                    if isProcessing {
                        ProgressView()
                    }
                }
            }
        } header: {
            Text("手動備份")
        } footer: {
            Text("將所有資料匯出為 JSON 檔案，可儲存到檔案 App 或傳送到其他裝置")
        }
    }

    var importSection: some View {
        Section {
            Button {
                showFileImporter = true
            } label: {
                Label("匯入資料", systemImage: "square.and.arrow.down")
            }
        } footer: {
            Text("從之前匯出的 JSON 檔案恢復資料。匯入後請重新啟動 App")
        }
    }
}

// MARK: - Actions

private extension BackupSettingsView {

    func performExport() {
        isProcessing = true

        Task {
            defer { isProcessing = false }

            do {
                let data = try BackupManager.exportBackup(context: coordinator.mainContext)
                let fileName = BackupManager.backupFileName()

                let tempDir = FileManager.default.temporaryDirectory
                let fileURL = tempDir.appendingPathComponent(fileName)
                try data.write(to: fileURL)

                exportedFileURL = fileURL
                showShareSheet = true
            } catch {
                alertTitle = "匯出失敗"
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }

    func handleFileImporterResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            pendingImportURL = url
            showImportConfirm = true
        case .failure(let error):
            alertTitle = "無法開啟檔案"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    func performImport(from url: URL) {
        isProcessing = true

        Task {
            defer {
                isProcessing = false
                pendingImportURL = nil
            }

            do {
                guard url.startAccessingSecurityScopedResource() else {
                    throw NSError(domain: "BackupManager", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "無法存取檔案"])
                }
                defer { url.stopAccessingSecurityScopedResource() }

                let data = try Data(contentsOf: url)
                let result = try BackupManager.importBackup(from: data, context: coordinator.mainContext)

                alertTitle = "匯入成功"
                alertMessage = "\(result.summary)\n\n請重新啟動 App 以載入所有資料。"
                showAlert = true
            } catch {
                alertTitle = "匯入失敗"
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

// MARK: - ShareSheet (UIKit wrapper)

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
