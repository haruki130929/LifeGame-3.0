import SwiftUI
import Charts

/// 練習日記的圖表統計頁
struct PracticeChartView: View {
    let diary: PracticeDiary
    @ObservedObject var store: PracticeDiaryStore

    private var entries: [PracticeEntry] {
        store.entries(for: diary.id).sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            if entries.isEmpty {
                ContentUnavailableView(
                    "還沒有紀錄",
                    systemImage: "chart.bar.xaxis",
                    description: Text("新增練習紀錄後即可查看統計圖表")
                )
                .padding(.top, 60)
            } else {
                LazyVStack(spacing: 20) {
                    // 個別欄位圖表
                    ForEach(chartableFields) { field in
                        chartSection(for: field)
                    }

                    // 雷達圖（綜合所有數值欄位的最新數據）
                    radarSection
                }
                .padding()
            }
        }
        .navigationTitle("統計圖表")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Chartable Fields

    private var chartableFields: [PracticeFieldDefinition] {
        diary.fields.filter { $0.effectiveChartType != nil }
    }

    // MARK: - Chart Section

    @ViewBuilder
    private func chartSection(for field: PracticeFieldDefinition) -> some View {
        switch field.effectiveChartType {
        case .line:
            lineChart(for: field)
        case .pie:
            pieChart(for: field)
        case .bar:
            barChart(for: field)
        case .radar:
            // 雷達圖在綜合區塊顯示
            EmptyView()
        case .none:
            EmptyView()
        }
    }

    // MARK: - 折線圖

    private func lineChart(for field: PracticeFieldDefinition) -> some View {
        let points = entries.compactMap { entry -> PracticeChartDataPoint? in
            guard let answer = entry.answers.first(where: { $0.questionId == field.question.id }),
                  let value = answer.intValue else { return nil }
            return PracticeChartDataPoint(date: entry.date, value: value)
        }

        let yMin = field.question.rangeMin ?? 0
        let yMax = field.question.rangeMax ?? (points.map(\.value).max() ?? 10)

        return DailyMetricLineChart(
            title: field.question.title,
            points: points,
            x: \.date,
            y: \.value,
            yDomain: yMin...yMax
        )
    }

    // MARK: - 圓餅圖

    private func pieChart(for field: PracticeFieldDefinition) -> some View {
        let counts = countStringValues(for: field)

        return VStack(alignment: .leading, spacing: 10) {
            Text(field.question.title)
                .font(.headline)

            if counts.isEmpty {
                Text("尚無資料")
                    .foregroundStyle(.secondary)
            } else {
                Chart(counts, id: \.label) { item in
                    SectorMark(
                        angle: .value("次數", item.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 1
                    )
                    .foregroundStyle(by: .value("選項", item.label))
                }
                .frame(height: 200)
                .padding(.vertical, 8)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - 長條圖

    private func barChart(for field: PracticeFieldDefinition) -> some View {
        let counts = countMultiSelectValues(for: field)

        return VStack(alignment: .leading, spacing: 10) {
            Text(field.question.title)
                .font(.headline)

            if counts.isEmpty {
                Text("尚無資料")
                    .foregroundStyle(.secondary)
            } else {
                Chart(counts, id: \.label) { item in
                    BarMark(
                        x: .value("選項", item.label),
                        y: .value("次數", item.count)
                    )
                    .foregroundStyle(.blue.gradient)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 200)
                .padding(.vertical, 8)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - 雷達圖（綜合）

    @ViewBuilder
    private var radarSection: some View {
        let numericFields = diary.fields.filter { field in
            field.question.type == .slider || field.question.type == .numberInput
        }

        if numericFields.count >= 3, !entries.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("綜合能力雷達圖")
                    .font(.headline)

                Text("基於最近一筆紀錄")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                let latestEntry = entries.last!
                let axes = numericFields.map { $0.question.title }
                let values = numericFields.map { field -> Double in
                    guard let answer = latestEntry.answers.first(where: { $0.questionId == field.question.id }),
                          let value = answer.intValue else { return 0 }
                    let max = Double(field.question.rangeMax ?? 10)
                    let min = Double(field.question.rangeMin ?? 0)
                    guard max > min else { return 0 }
                    return Double(value - Int(min)) / (max - min)
                }

                RadarChartView(axes: axes, values: values)
                    .frame(height: 250)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Data Helpers

    private func countStringValues(for field: PracticeFieldDefinition) -> [LabelCount] {
        var dict: [String: Int] = [:]
        for entry in entries {
            guard let answer = entry.answers.first(where: { $0.questionId == field.question.id }),
                  let value = answer.stringValue, !value.isEmpty else { continue }
            dict[value, default: 0] += 1
        }
        return dict.map { LabelCount(label: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private func countMultiSelectValues(for field: PracticeFieldDefinition) -> [LabelCount] {
        var dict: [String: Int] = [:]
        for entry in entries {
            guard let answer = entry.answers.first(where: { $0.questionId == field.question.id }),
                  let values = answer.stringArrayValue else { continue }
            for val in values {
                dict[val, default: 0] += 1
            }
        }
        return dict.map { LabelCount(label: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - Helper Types

struct PracticeChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Int
}

struct LabelCount {
    let label: String
    let count: Int
}
