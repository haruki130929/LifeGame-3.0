import SwiftUI

// MARK: - Small UI components

struct SectionHeaderText: View {
    let text: String
    init(_ text: String) { self.text = text }
    
    var body: some View {
        Text(text)
            .font(.headline)
            .padding(.top, 6)
    }
}

struct ScoreSliderRow: View {
    let title: String
    @Binding var value: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value)/10")
                    .foregroundStyle(.secondary)
            }
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0.rounded()) }
                ),
                in: 1...10,
                step: 1
            )
        }
        .padding(.vertical, 4)
    }
}

/// 多選格子（含 other + 文字框）
/// Option 必須是：Identifiable + Hashable + RawRepresentable(String)
struct MultiSelectGrid<Option: Identifiable & Hashable & RawRepresentable>: View where Option.RawValue == String {
    let title: String
    let options: [Option]
    @Binding var selected: Set<Option>
    let otherCase: Option
    @Binding var otherText: String
    
    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 8)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(options) { opt in
                    Toggle(isOn: bindingForSet(element: opt)) {
                        Text(opt.rawValue)
                    }
                }
            }
            
            if selected.contains(otherCase) {
                TextField("其他（請填寫）", text: $otherText)
            }
        }
    }
    
    private func bindingForSet(element: Option) -> Binding<Bool> {
        Binding(
            get: { selected.contains(element) },
            set: { isOn in
                if isOn { selected.insert(element) }
                else { selected.remove(element) }
            }
        )
    }
}

// MARK: - 30 分鐘時間選擇器（Date）

struct HalfHourTimePickerRow: View {
    let title: String
    @Binding var date: Date
    
    private let minutes = stride(from: 0, through: 24 * 60 - 30, by: 30).map { $0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty { Text(title) }
            
            Picker("", selection: Binding(
                get: { selectedMinutes(from: date) },
                set: { newMinutes in date = applyMinutesToSameDay(newMinutes, base: date) }
            )) {
                ForEach(minutes, id: \.self) { m in
                    Text(formatMinutes(m)).tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 140)
        }
    }
    
    private func selectedMinutes(from d: Date) -> Int {
        let cal = Calendar.current
        let h = cal.component(.hour, from: d)
        let m = cal.component(.minute, from: d)
        let rounded = Int((Double(m) / 30.0).rounded()) * 30
        let clamped = min(59, max(0, rounded))
        return h * 60 + clamped
    }
    
    private func applyMinutesToSameDay(_ minutes: Int, base: Date) -> Date {
        let cal = Calendar.current
        let h = minutes / 60
        let m = minutes % 60
        
        var comps = cal.dateComponents([.year, .month, .day], from: base)
        comps.hour = h
        comps.minute = m
        return cal.date(from: comps) ?? base
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%02d:%02d", h, m)
    }
}

// MARK: - 30 分鐘時間選擇器（OptionalLogTime：起床用）

struct HalfHourOptionalTimePickerRow: View {
    let title: String
    @Binding var value: OptionalLogTime
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Button {
                    toggleUnknown()
                } label: {
                    Text(value.isUnknown ? "已忘記" : "忘記紀錄")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            if value.isUnknown {
                Text("此欄位標記為忘記紀錄")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                HalfHourTimePickerRow(
                    title: "",
                    date: Binding(
                        get: { value.dateValue ?? Date() },
                        set: { value = .time($0) }
                    )
                )
            }
        }
    }
    
    private func toggleUnknown() {
        if value.isUnknown { value = .time(Date()) }
        else { value = .unknown }
    }
}

// MARK: - 0.5 單位數字 Picker（睡眠時長）

struct HalfHourNumberPickerRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Int>
    
    private var values: [Double] {
        var result: [Double] = []
        for h in range.lowerBound...range.upperBound {
            result.append(Double(h))
            if h != range.upperBound { result.append(Double(h) + 0.5) }
        }
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
            
            Picker("", selection: $value) {
                ForEach(values, id: \.self) { v in
                    Text(String(format: "%.1f", v)).tag(v)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 140)
        }
    }
}

struct OptionalHalfHourNumberPickerRow: View {
    let title: String
    @Binding var value: OptionalLogDouble
    let range: ClosedRange<Int>
    
    private var values: [Double] {
        var result: [Double] = []
        for h in range.lowerBound...range.upperBound {
            result.append(Double(h))
            if h != range.upperBound { result.append(Double(h) + 0.5) }
        }
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Button {
                    toggleUnknown()
                } label: {
                    Text(value.isUnknown ? "已忘記" : "忘記紀錄")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            if value.isUnknown {
                Text("此欄位標記為忘記紀錄")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Picker("", selection: Binding(
                    get: { value.doubleValue ?? 7.0 },
                    set: { value = .value($0) }
                )) {
                    ForEach(values, id: \.self) { v in
                        Text(String(format: "%.1f", v)).tag(v)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 140)
            }
        }
    }
    
    private func toggleUnknown() {
        if value.isUnknown { value = .value(7.0) }
        else { value = .unknown }
    }
}
