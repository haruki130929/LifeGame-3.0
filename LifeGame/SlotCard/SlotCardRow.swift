import SwiftUI

struct SlotCardRow: View {
    let type: CardType
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: type.icon)
                .frame(width: 24)
            
            Text(type.title)
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
    }
}
