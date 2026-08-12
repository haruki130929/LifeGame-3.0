import SwiftUI

/// 這個 Draft 只用在新增畫面，不會污染 RingItem 的模型
struct RingItemDraft {
    var title: String = String(localized: "新時段")
    var slot: DaySlot = .morning
    var icon: String = "clock"
    var colorHex: String = "4DA3FF"
    var hpCost: Int = 0
    var fpCost: Int = 0
    
    /// 分鐘（0...1439）
    var startMinute: Int = 9 * 60
    var endMinute: Int = 10 * 60
}

struct AddRingItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var draft: RingItemDraft
    
    /// 外面傳進來的保存行為
    let onSave: (RingItemDraft) -> Void
    
    init(defaultStartMinute: Int, onSave: @escaping (RingItemDraft) -> Void) {
        // 預設一段 60 分鐘，並且用 10 分鐘對齊
        let start = snap(defaultStartMinute, step: 10)
        let end = snap((start + 60) % 1440, step: 10)
        _draft = State(initialValue: RingItemDraft(startMinute: start, endMinute: end))
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本") {
                    TextField("名稱", text: $draft.title)

                    Picker("圖示", selection: $draft.icon) {
                        Label("時鐘", systemImage: "clock").tag("clock")
                        Label("書本", systemImage: "book").tag("book")
                        Label("走路", systemImage: "figure.walk").tag("figure.walk")
                        Label("用餐", systemImage: "fork.knife").tag("fork.knife")
                        Label("睡眠", systemImage: "moon").tag("moon")
                    }
                }
                
                Section("顏色") {
                    CompactPaletteColorPicker(selectedHex: $draft.colorHex)
                }
                
                Section("時間") {
                    timePickerRow(title: String(localized: "開始"), minute: $draft.startMinute)
                    timePickerRow(title: String(localized: "結束"), minute: $draft.endMinute)
                    
                    Text("會用 10 分鐘為單位對齊")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Section("消耗") {
                    Stepper("HP 消耗：\(draft.hpCost)P", value: $draft.hpCost, in: 0...100, step: 5)
                    Stepper("FP 消耗：\(draft.fpCost)P", value: $draft.fpCost, in: 0...100, step: 5)
                }
            }
            .navigationTitle("新增時段")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("加入") {
                        // 做一點點保護：結束若剛好等於開始，就自動加 10 分鐘
                        if draft.endMinute == draft.startMinute {
                            draft.endMinute = (draft.startMinute + 10) % 1440
                        }
                        onSave(draft)
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - UI pieces
    
    private func colorRow(_ name: String, _ hex: String) -> some View {
        Button {
            draft.colorHex = hex
        } label: {
            HStack {
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 10, height: 10)
                Text(name)
                Spacer()
                if draft.colorHex == hex {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
    }
    
    private func timePickerRow(title: String, minute: Binding<Int>) -> some View {
        let binding = Binding<Date>(
            get: { dateFromMinute(minute.wrappedValue) },
            set: { newDate in
                let m = minuteFromDate(newDate)
                minute.wrappedValue = snap(m, step: 10)
            }
        )
        
        return DatePicker(title, selection: binding, displayedComponents: .hourAndMinute)
            .datePickerStyle(.compact)
    }
}

// MARK: - Helpers

private func dateFromMinute(_ minute: Int) -> Date {
    var comps = DateComponents()
    comps.year = 2000
    comps.month = 1
    comps.day = 1
    comps.hour = minute / 60
    comps.minute = minute % 60
    return Calendar.current.date(from: comps) ?? Date()
}

private func minuteFromDate(_ date: Date) -> Int {
    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
    let h = comps.hour ?? 0
    let m = comps.minute ?? 0
    return (h * 60 + m) % 1440
}

private func snap(_ m: Int, step: Int) -> Int {
    let snapped = Int(round(Double(m) / Double(step))) * step
    return min(max(snapped, 0), 1440 - step)
}
