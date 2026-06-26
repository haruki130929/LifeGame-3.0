// ThemeStore.swift
import SwiftUI
import Combine

@MainActor
final class ThemeStore: ObservableObject {
    
    // MARK: - Types
    
    enum AccentPreset: Int, CaseIterable, Identifiable {
        case blue = 0
        case green = 1
        case orange = 2
        case purple = 3
        
        var id: Int { rawValue }
        
        var title: String {
            switch self {
            case .blue: return "藍"
            case .green: return "綠"
            case .orange: return "橘"
            case .purple: return "紫"
            }
        }
        
        var color: Color {
            switch self {
            case .blue: return .blue
            case .green: return .green
            case .orange: return .orange
            case .purple: return .purple
            }
        }
    }
    
    enum BackgroundStyle: Int, CaseIterable, Identifiable {
        case system = 0
        case gradient = 1
        case light = 2
        
        var id: Int { rawValue }
        
        var title: String {
            switch self {
            case .system: return "系統"
            case .gradient: return "漸層"
            case .light: return "淡色"
            }
        }
    }
    
    enum AppAppearance: Int, CaseIterable, Identifiable {
        case system = 0
        case light = 1
        case dark = 2
        
        var id: Int { rawValue }
        
        var title: String {
            switch self {
            case .system: return "跟隨系統"
            case .light: return "淺色"
            case .dark: return "深色"
            }
        }
        
        var preferredColorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    /// 卡片底樣式：實心 / 毛玻璃(Material)
    enum CardSurfaceStyle: Int, CaseIterable, Identifiable {
        case solid = 0
        case glass = 1

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .solid: return "實心"
            case .glass: return "毛玻璃"
            }
        }
    }
    
    // MARK: - Persist Keys
    
    private enum Keys {
        static let fontScale = "theme.fontScale"
        static let backgroundStyle = "theme.backgroundStyle"
        static let accentPreset = "theme.accentPreset"
        static let customAccentHex = "theme.customAccentHex"
        static let useCustomAccent = "theme.useCustomAccent"
        static let appearance = "theme.appearance"
        static let cardSurfaceStyle = "theme.cardSurfaceStyle"
    }
    
    // MARK: - Published
    
    @Published var fontScale: Double
    @Published var backgroundStyle: BackgroundStyle
    @Published var accentPreset: AccentPreset
    @Published var customAccentHex: String
    @Published var useCustomAccent: Bool
    @Published var appearance: AppAppearance
    /// 卡片底樣式（實心／毛玻璃／玻璃），預設毛玻璃
    @Published var cardSurfaceStyle: CardSurfaceStyle

    /// 用於在必要時強制刷新根視圖（保險用）
    @Published var refreshID: UUID = UUID()

    private var syncHelper: StoreSyncHelper?
    
    // MARK: - Keychain backup (survives app reinstall, no sync needed)

    /// Read from StorageManager first, then fall back to Keychain.
    private static func loadValue<T: Codable>(_ type: T.Type, key: String) -> T? {
        // 1. Try local (SwiftData)
        if let local: T = StorageManager.load(type, forKey: key) {
            return local
        }
        // 2. Fall back to Keychain (survives reinstall)
        return ThemeKeychain.load(type, forKey: key)
    }

    /// Save to both StorageManager and Keychain.
    private static func saveValue<T: Codable>(_ value: T, key: String) {
        StorageManager.save(value, forKey: key)
        ThemeKeychain.save(value, forKey: key)
    }

    // MARK: - Init

    init() {
        let savedScale: Double? = Self.loadValue(Double.self, key: Keys.fontScale)
        self.fontScale = savedScale ?? 1.0

        let bgRaw: Int = Self.loadValue(Int.self, key: Keys.backgroundStyle) ?? BackgroundStyle.system.rawValue
        self.backgroundStyle = BackgroundStyle(rawValue: bgRaw) ?? .system

        let presetRaw: Int = Self.loadValue(Int.self, key: Keys.accentPreset) ?? AccentPreset.blue.rawValue
        self.accentPreset = AccentPreset(rawValue: presetRaw) ?? .blue

        self.customAccentHex = Self.loadValue(String.self, key: Keys.customAccentHex) ?? ""
        self.useCustomAccent = Self.loadValue(Bool.self, key: Keys.useCustomAccent) ?? false

        let appRaw: Int = Self.loadValue(Int.self, key: Keys.appearance) ?? AppAppearance.system.rawValue
        self.appearance = AppAppearance(rawValue: appRaw) ?? .system

        let cardRaw: Int = Self.loadValue(Int.self, key: Keys.cardSurfaceStyle) ?? CardSurfaceStyle.glass.rawValue
        self.cardSurfaceStyle = CardSurfaceStyle(rawValue: cardRaw) ?? .glass

        // 一次性回填：確保舊版存的設定也備份到 Keychain
        backfillToKeychainIfNeeded()

        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    // MARK: - Cross-device Sync

    func reloadFromStorage() {
        let savedScale: Double? = Self.loadValue(Double.self, key: Keys.fontScale)
        fontScale = savedScale ?? 1.0

        let bgRaw: Int = Self.loadValue(Int.self, key: Keys.backgroundStyle) ?? BackgroundStyle.system.rawValue
        backgroundStyle = BackgroundStyle(rawValue: bgRaw) ?? .system

        let presetRaw: Int = Self.loadValue(Int.self, key: Keys.accentPreset) ?? AccentPreset.blue.rawValue
        accentPreset = AccentPreset(rawValue: presetRaw) ?? .blue

        customAccentHex = Self.loadValue(String.self, key: Keys.customAccentHex) ?? ""
        useCustomAccent = Self.loadValue(Bool.self, key: Keys.useCustomAccent) ?? false

        let appRaw: Int = Self.loadValue(Int.self, key: Keys.appearance) ?? AppAppearance.system.rawValue
        appearance = AppAppearance(rawValue: appRaw) ?? .system

        let cardRaw: Int = Self.loadValue(Int.self, key: Keys.cardSurfaceStyle) ?? CardSurfaceStyle.glass.rawValue
        cardSurfaceStyle = CardSurfaceStyle(rawValue: cardRaw) ?? .glass
    }

    /// 把目前的本地設定回填到 Keychain（只在 Keychain 為空時執行）
    private func backfillToKeychainIfNeeded() {
        guard ThemeKeychain.load(Int.self, forKey: Keys.accentPreset) == nil else { return }
        ThemeKeychain.save(fontScale, forKey: Keys.fontScale)
        ThemeKeychain.save(backgroundStyle.rawValue, forKey: Keys.backgroundStyle)
        ThemeKeychain.save(accentPreset.rawValue, forKey: Keys.accentPreset)
        ThemeKeychain.save(customAccentHex, forKey: Keys.customAccentHex)
        ThemeKeychain.save(useCustomAccent, forKey: Keys.useCustomAccent)
        ThemeKeychain.save(appearance.rawValue, forKey: Keys.appearance)
        ThemeKeychain.save(cardSurfaceStyle.rawValue, forKey: Keys.cardSurfaceStyle)
    }
    
    // MARK: - Computed

    /// 所有自訂 UI 都用這個判斷深淺模式，不依賴 @Environment(\.colorScheme)。
    /// 當 appearance 是 @Published，ThemeStore 的 objectWillChange 會讓所有
    /// 觀察者（@EnvironmentObject / @ObservedObject）即時重新繪製。
    var isDark: Bool {
        switch appearance {
        case .light:  return false
        case .dark:   return true
        case .system:
            return UITraitCollection.current.userInterfaceStyle == .dark
        }
    }

    var accentColor: Color {
        if useCustomAccent, let c = Color(hex: customAccentHex) {
            return c
        }
        return accentPreset.color
    }

    /// 浮動按鈕（左上選單、右上箭頭、FAB）底樣式：
    /// 毛玻璃模式用材質，否則維持原本半透明色。主面板永遠實心，不受此影響。
    var floatingButtonFill: AnyShapeStyle {
        if cardSurfaceStyle == .glass {
            return AnyShapeStyle(.ultraThinMaterial)
        }
        return AnyShapeStyle(isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.08))
    }

    // MARK: - Mutations (Save)
    
    func setFontScale(_ scale: Double) {
        fontScale = scale
        Self.saveValue(scale, key: Keys.fontScale)
    }

    func setBackgroundStyle(_ style: BackgroundStyle) {
        backgroundStyle = style
        Self.saveValue(style.rawValue, key: Keys.backgroundStyle)
    }

    func setAccentPreset(_ preset: AccentPreset) {
        accentPreset = preset
        useCustomAccent = false
        Self.saveValue(preset.rawValue, key: Keys.accentPreset)
        Self.saveValue(false, key: Keys.useCustomAccent)
    }

    func setUseCustomAccent(_ enabled: Bool) {
        useCustomAccent = enabled
        Self.saveValue(enabled, key: Keys.useCustomAccent)
    }

    /// 允許輸入 "#FF8800" / "FF8800" / "fff" 這三種
    func setCustomAccentHex(_ hex: String) {
        customAccentHex = hex
        Self.saveValue(hex, key: Keys.customAccentHex)

        if Color(hex: hex) != nil {
            useCustomAccent = true
            Self.saveValue(true, key: Keys.useCustomAccent)
        }
    }

    func setAppearance(_ a: AppAppearance) {
        appearance = a
        Self.saveValue(a.rawValue, key: Keys.appearance)
    }

    func setCardSurfaceStyle(_ style: CardSurfaceStyle) {
        cardSurfaceStyle = style
        Self.saveValue(style.rawValue, key: Keys.cardSurfaceStyle)
    }
    
    func bumpRefresh() {
        refreshID = UUID()
    }
}

// MARK: - Hex Color Helper

extension Color {
    /// 支援 "#RRGGBB" / "RRGGBB" / "RGB"
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        s = s.uppercased()
        
        let r, g, b: Double
        
        if s.count == 3 {
            let chars = Array(s)
            let rs = String(repeating: String(chars[0]), count: 2)
            let gs = String(repeating: String(chars[1]), count: 2)
            let bs = String(repeating: String(chars[2]), count: 2)
            guard
                let rv = UInt8(rs, radix: 16),
                let gv = UInt8(gs, radix: 16),
                let bv = UInt8(bs, radix: 16)
            else { return nil }
            r = Double(rv) / 255.0
            g = Double(gv) / 255.0
            b = Double(bv) / 255.0
        } else if s.count == 6 {
            guard let value = UInt32(s, radix: 16) else { return nil }
            let rv = UInt8((value >> 16) & 0xFF)
            let gv = UInt8((value >> 8) & 0xFF)
            let bv = UInt8(value & 0xFF)
            r = Double(rv) / 255.0
            g = Double(gv) / 255.0
            b = Double(bv) / 255.0
        } else {
            return nil
        }
        
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}

// MARK: - ThemeKeychain

/// Lightweight Keychain wrapper for theme settings.
/// Keychain data survives app uninstall on iOS.
private enum ThemeKeychain {
    private static let service = "com.haruki.lifegame.theme"

    static func save<T: Codable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }
}
