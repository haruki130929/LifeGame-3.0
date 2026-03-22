// CharacterStore.swift
import SwiftUI

@MainActor
final class CharacterStore: ObservableObject {

    // MARK: - Keys

    private enum Keys {
        static let name = "character.name"
        static let avatar = "character.avatar"
        static let abilities = "character.abilities"
    }

    /// 舊版 UserDefaults key（一次性遷移用）
    private enum LegacyKeys {
        static let name = "character_name_v1"
        static let avatar = "character_avatar_data"
        static let abilities = "character_abilities_v1"
        static let migrated = "character_migrated_to_sm"
    }

    // MARK: - Published

    @Published var name: String
    @Published private(set) var avatarData: Data?
    @Published var abilities: AbilitySet

    /// 方便 View 直接使用的計算屬性
    var avatarImage: UIImage? {
        guard let data = avatarData else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Init

    init() {
        // 先給預設值
        self.name = ""
        self.avatarData = nil
        self.abilities = .default

        // 一次性遷移舊 UserDefaults 資料
        migrateFromUserDefaultsIfNeeded()

        // 從 StorageManager 載入
        self.name = StorageManager.load(String.self, forKey: Keys.name) ?? ""
        self.avatarData = StorageManager.load(Data.self, forKey: Keys.avatar)
        self.abilities = StorageManager.load(AbilitySet.self, forKey: Keys.abilities) ?? .default
    }

    // MARK: - Mutations

    func setName(_ newName: String) {
        name = newName
        StorageManager.save(newName, forKey: Keys.name)
    }

    func setAvatar(_ image: UIImage?) {
        guard let image,
              let data = image.jpegData(compressionQuality: 0.7) else {
            avatarData = nil
            StorageManager.remove(forKey: Keys.avatar)
            return
        }
        avatarData = data
        StorageManager.save(data, forKey: Keys.avatar)
    }

    func setAbilities(_ newAbilities: AbilitySet) {
        abilities = newAbilities
        StorageManager.save(newAbilities, forKey: Keys.abilities)
    }

    // MARK: - Migration

    private func migrateFromUserDefaultsIfNeeded() {
        let ud = UserDefaults.standard
        guard !ud.bool(forKey: LegacyKeys.migrated) else { return }

        // 遷移名稱
        if let oldName = ud.string(forKey: LegacyKeys.name), !oldName.isEmpty {
            StorageManager.save(oldName, forKey: Keys.name)
        }

        // 遷移頭像
        if let oldAvatar = ud.data(forKey: LegacyKeys.avatar) {
            StorageManager.save(oldAvatar, forKey: Keys.avatar)
        }

        // 遷移能力值
        if let oldData = ud.data(forKey: LegacyKeys.abilities),
           let decoded = try? JSONDecoder().decode(AbilitySet.self, from: oldData) {
            StorageManager.save(decoded, forKey: Keys.abilities)
        }

        // 清除舊 key，標記已遷移
        ud.removeObject(forKey: LegacyKeys.name)
        ud.removeObject(forKey: LegacyKeys.avatar)
        ud.removeObject(forKey: LegacyKeys.abilities)
        ud.set(true, forKey: LegacyKeys.migrated)
    }
}
