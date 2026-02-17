import SwiftUI

struct MoodThermometerCard: View {
    @ObservedObject var mood: MoodStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("心情溫度計")
                .font(.headline)
            
            HStack {
                Text("分數")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(mood.score))")
                    .font(.headline)
                    .monospacedDigit()
            }
            
            Slider(
                value: $mood.score,
                in: 0...10,
                step: 1
            )
            
            Button {
                mood.save()
            } label: {
                Text("儲存")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
