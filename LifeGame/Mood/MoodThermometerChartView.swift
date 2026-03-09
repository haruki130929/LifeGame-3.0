import SwiftUI
import Charts

struct MoodThermometerChartView: View {
    let points: [MoodPoint]
    let startAt8: Date            // 今天 8:00
    let endAt8NextDay: Date       // 隔天 8:00
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今天心情折線圖（8:00 起算）")
                .font(.headline)
            
            Chart {
                ForEach(points) { p in
                    LineMark(
                        x: .value("時間", p.timestamp),
                        y: .value("分數", p.score)
                    )
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("時間", p.timestamp),
                        y: .value("分數", p.score)
                    )
                }
            }
            .chartYScale(domain: 0...10)
            .chartXScale(domain: startAt8...endAt8NextDay)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 2, 4, 6, 8, 10])
            }
            .chartXAxis {
                // 每 4 小時一個刻度：8,12,16,20,0,4,8
                AxisMarks(values: .stride(by: .hour, count: 4)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.hour(.twoDigits(amPM: .abbreviated)))
                }
            }
            .frame(height: 220)
            .padding(.vertical, 8)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
