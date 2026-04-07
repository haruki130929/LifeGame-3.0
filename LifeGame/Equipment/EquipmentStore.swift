// File: Equipment/EquipmentStore.swift
import SwiftUI
import Combine
import Foundation

@MainActor
final class EquipmentStore: ObservableObject {
    @Published var items: [EquipItem] = []
    private let key = "equipments_v1"
    private var syncHelper: StoreSyncHelper?
    
    init() {
        load()
        syncHelper = StoreSyncHelper { [weak self] in self?.reloadFromStorage() }
    }

    func reloadFromStorage() {
        if let decoded: [EquipItem] = StorageManager.load([EquipItem].self, forKey: key) {
            items = decoded
        }
    }
    
    func load() {
        if let decoded: [EquipItem] = StorageManager.load([EquipItem].self, forKey: key) {
            items = decoded
        }
    }
    
    func save() {
        StorageManager.save(items, forKey: key)
    }
}
