import SwiftUI

struct SimpleListCard: View {
    let title: String
    let icon: String
    let rows: [(String, String)]
    
    var body: some View {
        DashboardCardShell(title: title, icon: icon) {
            VStack(spacing: 10) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack {
                        Text(row.0)
                        Spacer()
                        Text(row.1)
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    
                    Divider().opacity(0.4)
                }
            }
        }
    }
}
