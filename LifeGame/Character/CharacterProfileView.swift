import SwiftUI

struct CharacterProfileView: View {
    @EnvironmentObject private var theme: ThemeStore
    @State private var abilities: AbilitySet = .default
    @State private var avatarImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var characterName: String = ""

    private let avatarStorageKey = "character_avatar_data"
    private let nameStorageKey = "character_name_v1"
    private let abilitiesStorageKey = "character_abilities_v1"

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
        .onAppear(perform: loadData)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $avatarImage, onDone: saveAvatar)
        }
    }

    // MARK: - iPad（左右並排）

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            // 左：頭像
            avatarSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // 右：能力值五角圖
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

            // 頭像
            Button {
                showImagePicker = true
            } label: {
                ZStack {
                    if let img = avatarImage {
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

                    // 編輯 badge
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

            // 名稱
            TextField("角色名稱", text: $characterName)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .frame(maxWidth: 200)
                .onChange(of: characterName) { _, newName in
                    UserDefaults.standard.set(newName, forKey: nameStorageKey)
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

            AbilityPentagonView(abilities: abilities, isDark: theme.isDark)
                .padding(.horizontal, 20)

            // 調整 Sliders
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

            Text("\(abilities.values[index])")
                .font(.caption.monospacedDigit())
                .frame(width: 24, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
    }

    private func bindingForIndex(_ index: Int) -> Binding<Double> {
        Binding<Double>(
            get: { Double(abilities.values[index]) },
            set: { newValue in
                let intVal = Int(newValue)
                switch index {
                case 0: abilities.stamina = intVal
                case 1: abilities.focus = intVal
                case 2: abilities.execution = intVal
                case 3: abilities.awareness = intVal
                case 4: abilities.timeManagement = intVal
                default: break
                }
                saveAbilities()
            }
        )
    }

    // MARK: - 持久化

    private func loadData() {
        // 名稱
        characterName = UserDefaults.standard.string(forKey: nameStorageKey) ?? ""

        // 頭像
        if let data = UserDefaults.standard.data(forKey: avatarStorageKey),
           let img = UIImage(data: data) {
            avatarImage = img
        }

        // 能力值
        if let data = UserDefaults.standard.data(forKey: abilitiesStorageKey),
           let decoded = try? JSONDecoder().decode(AbilitySet.self, from: data) {
            abilities = decoded
        }
    }

    private func saveAvatar() {
        guard let img = avatarImage,
              let data = img.jpegData(compressionQuality: 0.7) else { return }
        UserDefaults.standard.set(data, forKey: avatarStorageKey)
    }

    private func saveAbilities() {
        if let data = try? JSONEncoder().encode(abilities) {
            UserDefaults.standard.set(data, forKey: abilitiesStorageKey)
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onDone: () -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let edited = info[.editedImage] as? UIImage {
                parent.image = edited
            } else if let original = info[.originalImage] as? UIImage {
                parent.image = original
            }
            parent.onDone()
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
