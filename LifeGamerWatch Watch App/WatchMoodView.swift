import SwiftUI

struct WatchMoodView: View {
    @EnvironmentObject var dataStore: WatchDataStore
    @State private var moodValue: Double = 5
    @State private var showConfirmation = false

    private var moodEmoji: String {
        let v = Int(moodValue)
        switch v {
        case 0...1:  return "😢"
        case 2...3:  return "😔"
        case 4...5:  return "😐"
        case 6...7:  return "🙂"
        case 8...9:  return "😊"
        case 10:     return "😄"
        default:     return "😐"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("心情記錄")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // 表情 + 分數
            Text(moodEmoji)
                .font(.system(size: 44))

            Text("\(Int(moodValue))")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.yellow)

            Text("轉動錶冠調整")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            // 記錄按鈕
            Button {
                dataStore.recordMood(value: Int(moodValue))
                showConfirmation = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showConfirmation = false
                }
            } label: {
                Label(
                    showConfirmation ? "已記錄" : "記錄",
                    systemImage: showConfirmation ? "checkmark.circle.fill" : "heart.fill"
                )
                .font(.body.weight(.semibold))
            }
            .tint(showConfirmation ? .green : .yellow)
            .disabled(showConfirmation)
        }
        .padding(.horizontal, 4)
        .focusable()
        .digitalCrownRotation(
            $moodValue,
            from: 0,
            through: 10,
            by: 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
    }
}
