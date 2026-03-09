import SwiftUI

struct FloatingIconButton: View {
    let systemName: String
    var size: CGFloat = 44
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.headline)
                .frame(width: size, height: size)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}
