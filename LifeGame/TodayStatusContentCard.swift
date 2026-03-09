import SwiftUI

struct TodayStatusContentCard: View {
    @ObservedObject var game: LifeGame
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日狀態")
                .font(.headline)
            
            statRow(title: "HP", current: game.hp.current, max: game.hp.max)
            statRow(title: "FP", current: game.fp.current, max: game.fp.max)
            statRow(title: "MP", current: game.mp.current, max: game.mp.max)
            
            Divider().opacity(0.35)
            
            HStack(spacing: 10) {
                Button {
                    game.applyClassCost()
                } label: {
                    Text("上一堂課")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    game.settleToday()
                } label: {
                    Text("今日結算")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    @ViewBuilder
    private func statRow(title: String, current: Int, max: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text("\(current) / \(max)")
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(current), total: Double(max))
        }
    }
}
