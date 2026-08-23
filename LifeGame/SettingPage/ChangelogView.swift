import SwiftUI

/// 設定 →「開發日誌」：LifeGamer 從第一版到現在改過的每一件事。
///
/// 資料來自 `Changelog`，與更新後彈出的 `WhatsNewView` 是同一份。
struct ChangelogView: View {

    @EnvironmentObject private var theme: ThemeStore

    /// 展開中的版本號。預設只展開最新的一版 —— 全部展開會有五十幾列，
    /// 想找某一版反而得一直滑。
    @State private var expanded: Set<String>

    private let releases = Changelog.releases
    private let currentVersion = VersionTracker.currentVersion

    init() {
        _expanded = State(initialValue: Set(Changelog.releases.first.map { [$0.version] } ?? []))
    }

    var body: some View {
        List {
            introSection

            ForEach(releases) { release in
                Section {
                    DisclosureGroup(isExpanded: binding(for: release)) {
                        ForEach(release.items, id: \.title) { item in
                            itemRow(item)
                        }
                    } label: {
                        header(for: release)
                    }
                }
            }

            countSection
        }
        .navigationTitle(L10n.Settings.changelog)
        .navigationBarTitleDisplayMode(.inline)
        .hidesFab()
    }
}

// MARK: - Sections
private extension ChangelogView {

    var introSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("這個 App 改過什麼")
                    .font(.headline)
                Text("每一版的更新內容都留在這裡。想知道某個功能是什麼時候加的、或是哪個問題是哪一版修掉的，往下翻就找得到。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
        }
    }

    var countSection: some View {
        Section {
            EmptyView()
        } footer: {
            if let first = releases.last {
                Text("共 \(releases.count) 個版本，從 \(first.date) 開始。")
            }
        }
    }

    func header(for release: ChangelogRelease) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text("v\(release.version)")
                    .font(.headline.monospacedDigit())

                if release.matches(currentVersion) {
                    Text("目前版本")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(theme.accentColor.opacity(0.18), in: Capsule())
                        .foregroundStyle(theme.accentColor)
                }

                Spacer(minLength: 8)

                Text(release.date)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text(release.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }

    func itemRow(_ item: WhatsNewItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 18))
                .foregroundStyle(item.color)
                .frame(width: 28, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                Text(item.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }

    /// DisclosureGroup 需要 `Binding<Bool>`，但展開狀態存在一個 Set 裡
    /// （才能同時記住多個版本），這裡把兩者接起來。
    func binding(for release: ChangelogRelease) -> Binding<Bool> {
        Binding(
            get: { expanded.contains(release.version) },
            set: { isOpen in
                if isOpen {
                    expanded.insert(release.version)
                } else {
                    expanded.remove(release.version)
                }
            }
        )
    }
}
