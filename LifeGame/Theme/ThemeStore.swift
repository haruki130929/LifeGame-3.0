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
    
    // MARK: - Init
    
    init() {
        let savedScale: Double? = StorageManager.load(Double.self, forKey: Keys.fontScale)
        self.fontScale = savedScale ?? 1.0
        
        let bgRaw: Int = StorageManager.load(Int.self, forKey: Keys.backgroundStyle) ?? BackgroundStyle.system.rawValue
        self.backgroundStyle = BackgroundStyle(rawValue: bgRaw) ?? .system
        
        let presetRaw: Int = StorageManager.load(Int.self, forKey: Keys.accentPreset) ?? AccentPreset.blue.rawValue
        self.accentPreset = AccentPreset(rawValue: presetRaw) ?? .blue
        
        self.customAccentHex = StorageManager.load(String.self, forKey: Keys.customAccentHex) ?? ""
        self.useCustomAccent = StorageManager.load(Bool.self, forKey: Keys.useCustomAccent) ?? false
        
        let appRaw: Int = StorageManager.load(Int.self, forKey: Keys.appearance) ?? AppAppearance.system.rawValue
        self.appearance = AppAppearance(rawValue: appRaw) ?? .system
    }
    
    // MARK: - Computed
    
    var accentColor: Color {
        if useCustomAccent, let c = Color(hex: customAccentHex) {
            return c
        }
        return accentPreset.color
    }
    
    // MARK: - Mutations (Save)
    
    func setFontScale(_ scale: Double) {
        fontScale = scale
        StorageManager.save(scale, forKey: Keys.fontScale)
    }
    
    func setBackgroundStyle(_ style: BackgroundStyle) {
        backgroundStyle = style
        StorageManager.save(style.rawValue, forKey: Keys.backgroundStyle)
    }
    
    func setAccentPreset(_ preset: AccentPreset) {
        accentPreset = preset
        useCustomAccent = false
        StorageManager.save(preset.rawValue, forKey: Keys.accentPreset)
        StorageManager.save(false, forKey: Keys.useCustomAccent)
    }
    
    func setUseCustomAccent(_ enabled: Bool) {
        useCustomAccent = enabled
        StorageManager.save(enabled, forKey: Keys.useCustomAccent)
    }
    
    /// 允許輸入 "#FF8800" / "FF8800" / "fff" 這三種
    func setCustomAccentHex(_ hex: String) {
        customAccentHex = hex
        StorageManager.save(hex, forKey: Keys.customAccentHex)
        
        if Color(hex: hex) != nil {
            useCustomAccent = true
            StorageManager.save(true, forKey: Keys.useCustomAccent)
        }
    }
    
    func setAppearance(_ a: AppAppearance) {
        appearance = a
        StorageManager.save(a.rawValue, forKey: Keys.appearance)
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
