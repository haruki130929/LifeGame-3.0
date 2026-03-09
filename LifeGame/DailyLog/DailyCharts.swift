import SwiftUI
import Charts

// 單一折線圖（可重用）
struct DailyMetricLineChart<DataPoint: Identifiable>: View {
    let title: String
    let points: [DataPoint]
    let x: KeyPath<DataPoint, Date>
    let y: KeyPath<DataPoint, Int>
    
    // 分數範圍（依善甯的量表改：0...10、0...5、0...100 都可以）
    var yDomain: ClosedRange<Int> = 0...10
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            
            Chart(points) { p in
                LineMark(
                    x: .value("Date", p[keyPath: x]),
                    y: .value("Score", p[keyPath: y])
                )
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", p[keyPath: x]),
                    y: .value("Score", p[keyPath: y])
                )
            }
            .chartYScale(domain: yDomain.lowerBound...yDomain.upperBound)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 170)
            .padding(.vertical, 8)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
