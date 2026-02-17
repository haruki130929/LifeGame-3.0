//HabitModels
import SwiftUI
import Foundation

struct Habit: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var isActive: Bool = true
    var createdAt: Date = Date()
    
    init(id: UUID = UUID(), name: String, icon: String = "checkmark.circle", isActive: Bool = true) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isActive = isActive
    }
}
