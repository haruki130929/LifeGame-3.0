import Foundation
import Combine
import UIKit

/// 跨裝置同步輔助器 — 監聽 CloudKit 遠端變更 + App 回到前景，呼叫 Store 的 reload
///
/// 使用方式：
/// ```
/// class SomeStore: ObservableObject {
///     private var syncHelper: StoreSyncHelper?
///     private var isReloading = false
///
///     init() {
///         load()
///         syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
///     }
///
///     func reloadFromStorage() {
///         guard let saved = StorageManager.load(...) else { return }
///         guard saved != currentData else { return }
///         isReloading = true
///         currentData = saved
///         isReloading = false
///     }
/// }
/// ```
@MainActor
final class StoreSyncHelper {
    private var cancellable: AnyCancellable?

    init(reload: @escaping @MainActor () -> Void) {
        cancellable = NotificationCenter.default
            .publisher(for: StorageCoordinator.didReceiveRemoteChange)
            .merge(with: NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification))
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { _ in
                Task { @MainActor in reload() }
            }
    }
}
