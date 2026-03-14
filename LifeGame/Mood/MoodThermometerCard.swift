import SwiftUI

struct MoodThermometerCard: View {
    @ObservedObject var mood: MoodStore
    @EnvironmentObject private var history: MoodHistoryStore
    @EnvironmentObject private var moodSettings: MoodSettingsStore
    
    @State private var showHourlyLimitAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("心情溫度計")
                .font(.headline)
            
            // ✅ (B) 加這段：顯示小時區間
            Text("目前紀錄時間：\(currentHourRangeText())")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // ✅ 顯示目前分數（加在 Slider 上面）
            HStack {
                Text("分數")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(mood.score))")
                    .font(.headline)
            }
            
            // 你原本的 Slider（示意）
            Slider(value: $mood.score, in: moodSettings.scoreRange, step: 1)
            
            // ✅ (C) 把「儲存」改成「紀錄」，並寫入 history
            Button {
                let ok = history.add(score: mood.score, at: Date())
                if !ok { showHourlyLimitAlert = true }
            } label: {
                Text("紀錄")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .alert("這一小時已經記錄過了", isPresented: $showHourlyLimitAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("每小時只能記錄一次，下一個整點後再記錄。")
            }
        }
        .padding()
    }
    
    // ✅ 時間格式：13:00～14:00
    private func currentHourRangeText(now: Date = Date()) -> String {
        let cal = Calendar.current
        let interval = cal.dateInterval(of: .hour, for: now)!
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return "\(formatter.string(from: interval.start))～\(formatter.string(from: interval.end))"
    }
}
