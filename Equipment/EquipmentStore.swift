// File: Equipment/EquipmentStore.swift
import SwiftUI
import Foundation

final class EquipmentStore: ObservableObject {
    @Published var items: [EquipItem] = []
    private let key = "equipments_v1"
    
    init() { load() }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([EquipItem].self, from: data)
        else { return }
        items = decoded
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
