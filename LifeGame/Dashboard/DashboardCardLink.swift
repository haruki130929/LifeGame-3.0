import SwiftUI

struct DashboardCardLink<Destination: View, Label: View>: View {
    let destination: Destination
    @ViewBuilder let label: () -> Label
    
    var body: some View {
        NavigationLink(destination: destination) {
            label()
                .contentShape(RoundedRectangle(cornerRadius: 18)) // 讓整張都能點
        }
        .buttonStyle(.plain)
    }
}
