import SwiftUI

/// 新增任務（放一隻魚進缸）的小表單：標題 + 類型。
struct AquariumComposerView: View {
    @EnvironmentObject private var aquarium: AquariumStore
    @EnvironmentObject private var theme: ThemeStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var type: FishType

    init(initialType: FishType = .social) {
        _type = State(initialValue: initialType)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("任務") {
                    TextField("要做的事…", text: $title)
                }
                Section("類型") {
                    Picker("類型", selection: $type) {
                        ForEach(FishType.allCases) { t in
                            Label(t.label, systemImage: t.systemImage).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    HStack {
                        Spacer()
                        FishView(type: type,
                                 color: AquariumPalette.bodyColor(for: type, isDark: theme.isDark),
                                 facingLeft: false)
                            .frame(width: 76, height: 52)
                            .padding(.vertical, 4)
                        Spacer()
                    }
                    .listRowBackground(AquariumPalette.waterColor(isDark: theme.isDark))
                }
            }
            .navigationTitle("放一隻魚進缸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("放進去") {
                        aquarium.add(title: title, type: type)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
