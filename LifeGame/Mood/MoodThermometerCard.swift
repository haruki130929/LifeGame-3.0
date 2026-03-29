import SwiftUI

struct MoodThermometerCard: View {
    @ObservedObject var mood: MoodStore
    @EnvironmentObject private var history: MoodHistoryStore
    @EnvironmentObject private var moodSettings: MoodSettingsStore
    
    @State private var showHourlyLimitAlert = false
    @State private var showRecordedToast = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("心情溫度計")
                .font(.headline)

            Text("紀錄時段：\(previousHourRangeText())")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // 情緒
            HStack {
                Text("情緒")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(mood.score))")
                    .font(.headline)
            }
            Slider(value: $mood.score, in: moodSettings.scoreRange, step: 1)

            // 專注力
            HStack {
                Text("專注力")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(mood.focus))")
                    .font(.headline)
            }
            Slider(value: $mood.focus, in: moodSettings.scoreRange, step: 1)

            // 疲勞度
            HStack {
                Text("疲勞度")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(mood.fatigue))")
                    .font(.headline)
            }
            Slider(value: $mood.fatigue, in: moodSettings.scoreRange, step: 1)

            HStack {
                Spacer()
                Button {
                    let previousHour = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
                    let ok = history.add(score: mood.score, focus: mood.focus, fatigue: mood.fatigue, at: previousHour)
                    if ok {
                        showRecordedToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showRecordedToast = false
                        }
                    } else {
                        showHourlyLimitAlert = true
                    }
                } label: {
                    Text("紀錄上一小時")
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .alert("上一個小時已經記錄過了", isPresented: $showHourlyLimitAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text("每小時只能記錄一次，等這個小時結束後再記錄。")
            }
        }
        .padding()
        .overlay {
            if showRecordedToast {
                Text("已紀錄 ✓")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.green.gradient, in: Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: showRecordedToast)
    }
    
    // ✅ 時間格式：顯示上一個小時 e.g. 13:00～14:00（當前 14:xx 時）
    private func previousHourRangeText(now: Date = Date()) -> String {
        let cal = Calendar.current
        let previousHour = cal.date(byAdding: .hour, value: -1, to: now)!
        let interval = cal.dateInterval(of: .hour, for: previousHour)!
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return "\(formatter.string(from: interval.start))～\(formatter.string(from: interval.end))"
    }
}
