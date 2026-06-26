import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject var theme: ThemeStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var hasLoaded = false
    
    @State private var draftFontScale: Double = 1.0
    @State private var draftBackgroundStyle: ThemeStore.BackgroundStyle = .system
    @State private var draftAccentPreset: ThemeStore.AccentPreset = .blue
    
    @State private var draftUseCustomAccent: Bool = false
    @State private var draftCustomHex: String = ""
    
    @State private var draftAppearance: ThemeStore.AppAppearance = .system

    @State private var draftCardSurface: ThemeStore.CardSurfaceStyle = .glass

    // MARK: - Derived
    private var trimmedHex: String {
        draftCustomHex.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var isHexValid: Bool {
        Color(hex: trimmedHex) != nil
    }
    
    private var previewAccent: Color {
        if draftUseCustomAccent, let c = Color(hex: trimmedHex) { return c }
        return draftAccentPreset.color
    }
    
    private var canSave: Bool {
        // 開了自訂就必須是有效色碼
        !(draftUseCustomAccent && !isHexValid)
    }
    
    var body: some View {
        List {
            // MARK: 主色
            Section("主色") {
                ScrollPaletteColorPicker(selectedHex: Binding(
                    get: { draftCustomHex },
                    set: { newHex in
                        draftCustomHex = newHex
                        draftUseCustomAccent = true
                    }
                ))
            }
            
            // MARK: 字體大小
            Section("字體大小") {
                Slider(value: $draftFontScale, in: 0.85...1.25, step: 0.05)
                    .tint(previewAccent)
                
                Text("倍率：\(draftFontScale, specifier: "%.2f")")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            // MARK: 背景
            Section("背景") {
                Picker("背景樣式", selection: $draftBackgroundStyle) {
                    ForEach(ThemeStore.BackgroundStyle.allCases) { s in
                        Text(s.title).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .tint(previewAccent)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(.secondary.opacity(0.12))
                    .frame(height: 52)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary.opacity(0.18), lineWidth: 1))
            }
            
            // MARK: 頁面主題
            Section("頁面主題") {
                Picker("模式", selection: $draftAppearance) {
                    ForEach(ThemeStore.AppAppearance.allCases) { a in
                        Text(a.title).tag(a)
                    }
                }
                .pickerStyle(.segmented)
                .tint(previewAccent)
            }

            // MARK: 卡片
            Section {
                Picker("卡片材質", selection: $draftCardSurface) {
                    ForEach(ThemeStore.CardSurfaceStyle.allCases) { s in
                        Text(s.title).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .tint(previewAccent)
            } header: {
                Text("卡片")
            } footer: {
                Text("卡片底樣式（主面板維持實心）。毛玻璃與玻璃在背景豐富時最明顯。")
            }
        }
        .navigationTitle("外觀")
        .onAppear {
            guard !hasLoaded else { return }
            hasLoaded = true
            
            draftFontScale = theme.fontScale
            draftBackgroundStyle = theme.backgroundStyle
            draftAccentPreset = theme.accentPreset
            draftUseCustomAccent = theme.useCustomAccent
            draftCustomHex = theme.customAccentHex
            draftAppearance = theme.appearance
            draftCardSurface = theme.cardSurfaceStyle
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") { save() }
                    .disabled(!canSave)
            }
        }
    }
    
    private func save() {
        theme.setFontScale(draftFontScale)
        theme.setBackgroundStyle(draftBackgroundStyle)
        theme.setAppearance(draftAppearance)
        theme.setCardSurfaceStyle(draftCardSurface)

        if draftUseCustomAccent {
            // 自訂色：只有在有效時才真的開（canSave 已擋掉）
            theme.setCustomAccentHex(trimmedHex)
            theme.setUseCustomAccent(true)
        } else {
            // 預設色
            theme.setAccentPreset(draftAccentPreset)
            theme.setUseCustomAccent(false)
        }
        
        theme.bumpRefresh()
        dismiss()
    }
}
