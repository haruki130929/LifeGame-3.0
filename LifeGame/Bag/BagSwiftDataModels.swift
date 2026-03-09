import Foundation
import SwiftData

@Model
final class BagItemModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var isRequired: Bool
    var isChecked: Bool   // ✅ 新增：把「是否勾選」也存到 SwiftData
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        isRequired: Bool = false,
        isChecked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isRequired = isRequired
        self.isChecked = isChecked
    }
}
