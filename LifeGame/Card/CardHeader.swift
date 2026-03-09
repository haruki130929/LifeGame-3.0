import SwiftUI

struct CardHeader: View {
    let title: String
    let icon: String
    var showsChevron: Bool = true
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(title)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
            
            if showsChevron {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct CardSubtitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    
    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
    }
}
