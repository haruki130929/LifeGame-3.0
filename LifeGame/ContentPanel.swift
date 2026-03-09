import SwiftUI

struct ContentPanel: View {
    @Binding var isOpen: Bool
    @ObservedObject var game: LifeGame
    @ObservedObject var mood: MoodStore
    var onNavigateToMood: (() -> Void)? = nil

    private let cornerRadius: CGFloat = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Content").font(.title2).bold()
                Spacer()
                Button {
                    withAnimation(.spring()) { isOpen = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }

            Divider()

            TodayStatusContentCard(game: game)

            VStack(alignment: .leading, spacing: 0) {
                MoodThermometerCard(mood: mood)

                if onNavigateToMood != nil {
                    Button {
                        onNavigateToMood?()
                    } label: {
                        HStack {
                            Text("查看完整圖表")
                                .font(.footnote.weight(.medium))
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .padding(.trailing, 12)
        .padding(.vertical, 12)
        .shadow(radius: 12)
    }
}
