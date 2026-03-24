import Foundation
import SwiftData

@Model
final class BagItemModel {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = ""
    var isRequired: Bool = false
    var isChecked: Bool = false
    
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
