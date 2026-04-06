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
    
    // MARK: - Persist Keys
    
    private enum Keys {
        static let fontScale = "theme.fontScale"
        static let backgroundStyle = "theme.backgroundStyle"
        static let accentPreset = "theme.accentPreset"
        static let customAccentHex = "theme.customAccentHex"
        static let useCustomAccent = "theme.useCustomAccent"
        static let appearance = "theme.appearance"
    }
    
    // MARK: - Published
    
    @Published var fontScale: Double
    @Published var backgroundStyle: BackgroundStyle
    @Published var accentPreset: AccentPreset
    @Published var customAccentHex: String
    @Published var useCustomAccent: Bool
    @Published var appearance: AppAppearance
    
    /// 用於在必要時強制刷新根視圖（保險用）
    @Published var refreshID: UUID = UUID()
    
    // MARK: - iCloud key-value backup (instant sync, survives reinstall)

    private static let ubiq = NSUbiquitousKeyValueStore.default

    /// Read from StorageManager first, then fall back to iCloud KV store.
    /// This ensures theme survives app reinstall.
    private static func loadValue<T: Codable>(_ type: T.Type, key: String) -> T? {
        // 1. Try local (SwiftData) — most up-to-date
        if let local: T = StorageManager.load(type, forKey: key) {
            return local
        }
        // 2. Fall back to iCloud KV store — survives reinstall
        return ubiq.object(forKey: key) as? T
    }

    /// Save to both StorageManager and iCloud KV store.
    private static func saveValue<T: Codable>(_ value: T, key: String) {
        StorageManager.save(value, forKey: key)
        // Also mirror to iCloud KV store for reinstall recovery
        if let intVal = value as? Int {
            ubiq.set(intVal, forKey: key)
        } else if let doubleVal = value as? Double {
            ubiq.set(doubleVal, forKey: key)
        } else if let stringVal = value as? String {
            ubiq.set(stringVal, forKey: key)
        } else if let boolVal = value as? Bool {
            ubiq.set(boolVal, forKey: key)
        }
        ubiq.synchronize()
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

        // 一次性回填：如果本地有資料但 iCloud KV 還沒有，把現有設定同步上去
        // 這確保舊版存的設定也能備份到 iCloud KV
        backfillToUbiquitousStoreIfNeeded()
    }

    /// 把目前的本地設定回填到 iCloud KV（只在 iCloud KV 為空時執行）
    private func backfillToUbiquitousStoreIfNeeded() {
        let ubiq = Self.ubiq
        // 用 accentPreset 作為指標：如果 iCloud KV 裡沒有這個 key，代表從未回填過
        guard ubiq.object(forKey: Keys.accentPreset) == nil else { return }

        ubiq.set(fontScale, forKey: Keys.fontScale)
        ubiq.set(backgroundStyle.rawValue, forKey: Keys.backgroundStyle)
        ubiq.set(accentPreset.rawValue, forKey: Keys.accentPreset)
        ubiq.set(customAccentHex, forKey: Keys.customAccentHex)
        ubiq.set(useCustomAccent, forKey: Keys.useCustomAccent)
        ubiq.set(appearance.rawValue, forKey: Keys.appearance)
        ubiq.synchronize()
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
