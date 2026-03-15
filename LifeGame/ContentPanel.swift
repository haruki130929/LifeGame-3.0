import SwiftUI

struct ContentPanel: View {
    @Binding var isOpen: Bool
    @ObservedObject var game: LifeGame
    @ObservedObject var mood: MoodStore
    var onNavigateToMood: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("工具欄").font(.title2).bold()
                Spacer()
                Button {
                    withAnimation(.easeInOut) { isOpen = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 40, height: 40)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                        .accessibilityLabel("關閉")
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
        .padding(.top, 36)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.ultraThinMaterial)
        .ignoresSafeArea()
    }
}
