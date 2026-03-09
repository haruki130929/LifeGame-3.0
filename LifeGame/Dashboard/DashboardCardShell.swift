import SwiftUI

struct DashboardCardShell<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 32, height: 32)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Text(title)
                    .font(.headline)
                
                Spacer()
            }
            
            content
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(radius: 10)
    }
}
