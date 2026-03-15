// File: Equipment/EquipmentStore.swift
import SwiftUI
import Combine
import Foundation

final class EquipmentStore: ObservableObject {
    @Published var items: [EquipItem] = []
    private let key = "equipments_v1"
    
    init() { load() }
    
    func load() {
        if let decoded: [EquipItem] = StorageManager.load([EquipItem].self, forKey: key) {
            items = decoded
        }
    }
    
    func save() {
        StorageManager.save(items, forKey: key)
    }
}
