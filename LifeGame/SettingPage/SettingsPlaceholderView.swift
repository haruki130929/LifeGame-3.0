import SwiftUI

struct SettingsPlaceholderView: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(subtitle)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
