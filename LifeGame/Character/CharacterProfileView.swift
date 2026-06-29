import SwiftUI
import PhotosUI

struct CharacterProfileView: View {
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var character: CharacterStore
    @State private var avatarPickerItem: PhotosPickerItem? = nil

    var body: some View {
        Group {
            if AppLayout.isIPad {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .navigationTitle("角色設定")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: avatarPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    character.setAvatar(image)
                }
                // 載入後清空，讓使用者可重複選同一張
                avatarPickerItem = nil
            }
        }
    }

    // MARK: - iPad（左右並排）

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            avatarSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            abilitySection
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - iPhone（上下排列）

    private var iPhoneLayout: some View {
        ScrollView {
            VStack(spacing: 24) {
                avatarSection
                    .frame(height: 280)
                abilitySection
            }
            .padding(.bottom, 80)
        }
    }

    // MARK: - 頭像區塊

    private var avatarSection: some View {
        VStack(spacing: 16) {
            Spacer()

            PhotosPicker(selection: $avatarPickerItem, matching: .images) {
                ZStack {
                    if let img = character.avatarImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(theme.isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                            .frame(width: 140, height: 140)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.secondary)
                            )
                    }

                    Circle()
                        .fill(theme.isDark ? Color.white.opacity(0.2) : Color.black.opacity(0.1))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(theme.isDark ? .white : Color(.label))
                        )
                        .offset(x: 50, y: 50)
                }
            }
            .buttonStyle(.plain)

            TextField("角色名稱", text: $character.name)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .frame(maxWidth: 200)
                .onChange(of: character.name) { _, newName in
                    character.setName(newName)
                }

            Spacer()
        }
        .padding()
    }

    // MARK: - 能力值區塊

    private var abilitySection: some View {
        VStack(spacing: 16) {
            Text("能力值")
                .font(.headline)

            AbilityPentagonView(abilities: character.abilities, isDark: theme.isDark)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { i in
                    abilitySlider(index: i)
                }
            }
            .padding(.horizontal, 24)
        }
        .padding()
    }

    private func abilitySlider(index: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: AbilitySet.icons[index])
                .font(.system(size: 14))
                .frame(width: 20)
                .foregroundStyle(.secondary)

            Text(AbilitySet.labels[index])
                .font(.caption)
                .frame(width: 56, alignment: .leading)

            Slider(
                value: bindingForIndex(index),
                in: 0...Double(AbilitySet.maxValue),
                step: 1
            )
            .tint(.cyan)

            Text("\(character.abilities.values[index])")
                .font(.caption.monospacedDigit())
                .frame(width: 24, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
    }

    private func bindingForIndex(_ index: Int) -> Binding<Double> {
        Binding<Double>(
            get: { Double(character.abilities.values[index]) },
            set: { newValue in
                var updated = character.abilities
                let intVal = Int(newValue)
                switch index {
                case 0: updated.stamina = intVal
                case 1: updated.focus = intVal
                case 2: updated.execution = intVal
                case 3: updated.awareness = intVal
                case 4: updated.timeManagement = intVal
                default: break
                }
                character.setAbilities(updated)
            }
        )
    }
}
