import SwiftUI
import Combine

@MainActor
final class AppUpdateChecker: ObservableObject {
    @Published var hasUpdate: Bool = false
    @Published var latestVersion: String?

    private var appStoreID: String?
    private var cancellable: AnyCancellable?

    init() {
        checkForUpdate()

        // 每次 App 回到前景時重新檢查
        cancellable = NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.checkForUpdate()
                }
            }
    }

    func checkForUpdate() {
        guard let bundleId = Bundle.main.bundleIdentifier else { return }
        let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleId)&country=tw"
        guard let url = URL(string: urlString) else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let result = try JSONDecoder().decode(LookupResult.self, from: data)
                guard let info = result.results.first else { return }

                appStoreID = "\(info.trackId)"
                latestVersion = info.version

                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
                hasUpdate = isVersion(info.version, newerThan: currentVersion)
            } catch {
                // 網路錯誤時靜默失敗，不影響使用者體驗
            }
        }
    }

    func openAppStore() {
        guard let id = appStoreID,
              let url = URL(string: "itms-apps://itunes.apple.com/app/id\(id)") else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Version comparison

    private func isVersion(_ remote: String, newerThan local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        let count = max(r.count, l.count)
        for i in 0..<count {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv > lv { return true }
            if rv < lv { return false }
        }
        return false
    }
}

// MARK: - iTunes Lookup API Response

private struct LookupResult: Decodable {
    let resultCount: Int
    let results: [AppInfo]
}

private struct AppInfo: Decodable {
    let trackId: Int
    let version: String
}
