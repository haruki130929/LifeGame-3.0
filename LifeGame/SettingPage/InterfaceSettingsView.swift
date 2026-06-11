import SwiftUI

// MARK: - FAB 操作模式

enum FabStyle: String, CaseIterable, Identifiable, Codable {
    case ring = "ring"      // 長按圓環
    case menu = "menu"      // 膠囊選單（同 iPad）

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ring: return "手勢圓環"
        case .menu: return "展開選單"
        }
    }

    var description: String {
        switch self {
        case .ring: return "長按「＋」後滑動選取功能"
        case .menu: return "點擊「＋」展開選單按鈕"
        }
    }

    var icon: String {
        switch self {
        case .ring: return "circle.dotted"
        case .menu: return "list.bullet"
        }
    }

    // MARK: - 持久化（StorageManager）

    private static let storageKey = "fab.style"
    private static let legacyKey = "fab_style_v1"

    static var current: FabStyle {
        get {
            migrateLegacyIfNeeded()
            return StorageManager.load(FabStyle.self, forKey: storageKey) ?? .ring
        }
        set {
            StorageManager.save(newValue, forKey: storageKey)
        }
    }

    private static func migrateLegacyIfNeeded() {
        let ud = UserDefaults.standard
        guard let raw = ud.string(forKey: legacyKey),
              let style = FabStyle(rawValue: raw) else { return }
        StorageManager.save(style, forKey: storageKey)
        ud.removeObject(forKey: legacyKey)
    }
}

// MARK: - FAB 慣用手 / 位置（左下 ↔ 右下）

enum FabHandedness: String, CaseIterable, Identifiable {
    case right = "right"   // 右撇子 → 右下角
    case left = "left"     // 左撇子 → 左下角

    var id: String { rawValue }

    /// @AppStorage 共用的 UserDefaults key
    static let storageKey = "fab.handedness"

    var title: String {
        switch self {
        case .right: return "右下角（右手）"
        case .left:  return "左下角（左手）"
        }
    }

    var description: String {
        switch self {
        case .right: return "「＋」按鈕放在螢幕右下角"
        case .left:  return "「＋」按鈕放在螢幕左下角"
        }
    }

    var icon: String {
        switch self {
        case .right: return "arrow.down.right.circle"
        case .left:  return "arrow.down.left.circle"
        }
    }
}

// MARK: - 介面操作設定頁

struct InterfaceSettingsView: View {
    @EnvironmentObject private var theme: ThemeStore
    @State private var fabStyle: FabStyle = FabStyle.current
    @AppStorage(FabHandedness.storageKey) private var handedness: FabHandedness = .right

    var body: some View {
        Form {
            Section {
                ForEach(FabStyle.allCases) { style in
                    Button {
                        fabStyle = style
                        FabStyle.current = style
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: style.icon)
                                .font(.title3)
                                .frame(width: 30)
                                .foregroundStyle(fabStyle == style ? theme.accentColor : .secondary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(style.title)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color(.label))
                                Text(style.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if fabStyle == style {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(theme.accentColor)
                                    .font(.body.weight(.semibold))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("「＋」按鈕操作方式")
            } footer: {
                Text("僅影響 iPhone 版，iPad 版固定為展開選單")
            }

            Section {
                ForEach(FabHandedness.allCases) { side in
                    Button {
                        handedness = side
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: side.icon)
                                .font(.title3)
                                .frame(width: 30)
                                .foregroundStyle(handedness == side ? theme.accentColor : .secondary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(side.title)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color(.label))
                                Text(side.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if handedness == side {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(theme.accentColor)
                                    .font(.body.weight(.semibold))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("「＋」按鈕位置")
            } footer: {
                Text("左撇子可放左下角，慣用手更好按（僅影響 iPhone 版）")
            }
        }
        .navigationTitle("介面操作")
        .navigationBarTitleDisplayMode(.inline)
    }
}
