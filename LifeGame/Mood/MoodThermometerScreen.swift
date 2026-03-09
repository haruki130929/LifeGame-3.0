import SwiftUI

struct MoodThermometerScreen: View {
    @StateObject private var mood = MoodStore()
    @EnvironmentObject private var history: MoodHistoryStore
    
    @State private var showHourlyLimitAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                let range = todayRangeStartingAt8()
                let todaysPoints = history.points(in: range.start...range.end)
                
                MoodThermometerChartView(
                    points: todaysPoints,
                    startAt8: range.start,
                    endAt8NextDay: range.end
                )
                
                MoodThermometerCard(mood: mood)
                
                Button {
                    // ✅ 這裡請用你 MoodStore 真正的分數屬性名稱
                    // 常見是 mood.score；如果你不是叫 score，改成你的名稱即可
                    let ok = history.add(score: mood.score, at: Date())
                    if !ok { showHourlyLimitAlert = true }
                } label: {
                    Label("記錄一次（存到折線圖）", systemImage: "plus.circle.fill")
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
        .navigationTitle("心情溫度計")
    }
    
    /// 回傳「今天 8:00」到「隔天 8:00」的區間
    private func todayRangeStartingAt8(now: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        
        // 今天 00:00
        let startOfDay = calendar.startOfDay(for: now)
        
        // 今天 8:00
        let today8 = calendar.date(byAdding: .hour, value: 8, to: startOfDay)!
        
        // 如果現在 < 今天 8:00，代表仍屬於「昨天 8:00～今天 8:00」區間
        let start: Date = (now < today8)
        ? calendar.date(byAdding: .day, value: -1, to: today8)!
        : today8
        
        let end = calendar.date(byAdding: .hour, value: 24, to: start)!
        return (start, end)
    }
}
