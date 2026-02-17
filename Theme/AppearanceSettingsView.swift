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
                HStack(spacing: 12) {
                    ForEach(ThemeStore.AccentPreset.allCases) { p in
                        Button {
                            draftAccentPreset = p
                            // 選 preset 的當下：切回 preset 模式
                            draftUseCustomAccent = false
                        } label: {
                            Text(p.title)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(p.color)
                        .opacity(draftAccentPreset == p && !draftUseCustomAccent ? 1.0 : 0.55)
                    }
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("自訂顏色碼（Hex）")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 10) {
                        TextField("例如 #FF8800", text: $draftCustomHex)
                            .textInputAutocapitalization(.characters)
                            .disableAutocorrection(true)
                            .onChange(of: draftCustomHex) { _, newValue in
                                // 輸入一變成有效色碼，就自動切到自訂模式
                                if Color(hex: newValue.trimmingCharacters(in: .whitespacesAndNewlines)) != nil {
                                    draftUseCustomAccent = true
                                }
                            }
                        
                        Circle()
                            .fill(previewAccent)
                            .frame(width: 18, height: 18)
                            .overlay(Circle().stroke(.secondary.opacity(0.35), lineWidth: 1))
                    }
                    
                    Toggle("使用自訂色", isOn: $draftUseCustomAccent)
                        .disabled(trimmedHex.isEmpty)
                    
                    if !trimmedHex.isEmpty && !isHexValid {
                        Text("色碼格式不正確（可用：#RRGGBB 或 RRGGBB 或 RGB）")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
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
