import SwiftUI

// MARK: - FAB 操作模式

enum FabStyle: String, CaseIterable, Identifiable {
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

    // MARK: - 持久化

    private static let storageKey = "fab_style_v1"

    static var current: FabStyle {
        get {
            guard let raw = UserDefaults.standard.string(forKey: storageKey),
                  let style = FabStyle(rawValue: raw) else {
                return .ring  // 預設圓環
            }
            return style
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
        }
    }
}

// MARK: - 介面操作設定頁

struct InterfaceSettingsView: View {
    @State private var fabStyle: FabStyle = FabStyle.current

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
                                .foregroundStyle(fabStyle == style ? .blue : .secondary)

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
                                    .foregroundStyle(.blue)
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
        }
        .navigationTitle("介面操作")
        .navigationBarTitleDisplayMode(.inline)
    }
}
