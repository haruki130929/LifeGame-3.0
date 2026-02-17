import SwiftUI

struct DailyLogEditorView: View {
    
    @State var entry: DailyLogEntry
    var onSave: (DailyLogEntry) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    enum Tab: Int, CaseIterable, Hashable {
        case basic, emotion, sleep, study, body, note
        
        var title: String {
            switch self {
            case .basic: return "基本"
            case .emotion: return "情緒"
            case .sleep: return "睡眠"
            case .study: return "課業"
            case .body: return "身體"
            case .note: return "備註"
            }
        }
    }
    
    @State private var tab: Tab = .basic
    
    var body: some View {
        ZStack {
            // 背景（如果你已有 ThemeBackgroundView，就換成你的）
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // ✅ 檔案夾標籤列
                FolderTabs(
                    tabs: [.basic, .emotion, .sleep, .study, .body, .note],
                    selection: $tab,
                    title: { t in
                        switch t {
                        case .basic: return "基本"
                        case .emotion: return "情緒"
                        case .sleep: return "睡眠"
                        case .study: return "課業"
                        case .body: return "身體"
                        case .note: return "備註"
                        }
                    }
                )
                
                // ✅ 白色內容卡片（像你圖裡那個大白框）
                VStack {
                    Form {
                        switch tab {
                        case .basic: BasicSection(entry: $entry)
                        case .emotion: EmotionSection(entry: $entry)
                        case .sleep: SleepSection(entry: $entry)
                        case .study: StudySection(entry: $entry)
                        case .body: BodySection(entry: $entry)
                        case .note: NoteSection(entry: $entry)
                        }
                    }
                    .scrollContentBackground(.hidden) // 讓 Form 背景透明
                }
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.75), lineWidth: 2)
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .navigationTitle("每日紀錄")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("儲存") {
                    onSave(entry)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - 基本
struct BasicSection: View {
    @Binding var entry: DailyLogEntry
    
    var body: some View {
        Section("基本資訊") {
            DatePicker("日期", selection: $entry.date, displayedComponents: .date)
            DatePicker("起床時間", selection: $entry.wakeTime, displayedComponents: .hourAndMinute)
            
            Picker("天氣", selection: $entry.weather) {
                ForEach(Weather.allCases) { w in
                    Text(w.rawValue).tag(w)
                }
            }
        }
    }
}


// MARK: - 情緒
struct EmotionSection: View {
    @Binding var entry: DailyLogEntry
    
    var body: some View {
        Section("情緒與心理狀態") {
            
            VStack(alignment: .leading) {
                Text("整體情緒：\(entry.overallMoodScore)")
                Slider(value: Binding(
                    get: { Double(entry.overallMoodScore) },
                    set: { entry.overallMoodScore = Int($0) }
                ), in: 0...10, step: 1)
            }
            
            VStack(alignment: .leading) {
                Text("焦慮程度：\(entry.anxietyScore)")
                Slider(value: Binding(
                    get: { Double(entry.anxietyScore) },
                    set: { entry.anxietyScore = Int($0) }
                ), in: 0...10, step: 1)
            }
        }
    }
}


// MARK: - 睡眠
struct SleepSection: View {
    @Binding var entry: DailyLogEntry
    
    var body: some View {
        Section("睡眠狀況") {
            
            DatePicker("上床時間", selection: $entry.bedTime, displayedComponents: .hourAndMinute)
            
            Picker("入睡時間", selection: $entry.sleepLatency) {
                ForEach(SleepLatency.allCases) {
                    Text($0.rawValue).tag($0)
                }
            }
            
            Stepper("睡眠時長：\(entry.sleepHours, specifier: "%.1f") 小時",
                    value: $entry.sleepHours,
                    in: 0...15,
                    step: 0.5)
            
            Picker("睡眠品質", selection: $entry.sleepQuality) {
                ForEach(SleepQuality.allCases) {
                    Text($0.rawValue).tag($0)
                }
            }
        }
    }
}


// MARK: - 課業
struct StudySection: View {
    @Binding var entry: DailyLogEntry
    
    var body: some View {
        Section("課業與專注力") {
            
            Picker("專注度", selection: $entry.focusQuality) {
                ForEach(FocusQuality.allCases) {
                    Text($0.rawValue).tag($0)
                }
            }
            
            Toggle("未完成事項", isOn: $entry.unfinished)
            
            if entry.unfinished {
                Stepper("未完成數量：\(entry.unfinishedCount)",
                        value: $entry.unfinishedCount,
                        in: 0...20)
            }
        }
    }
}


// MARK: - 身體
struct BodySection: View {
    @Binding var entry: DailyLogEntry
    
    var body: some View {
        Section("身體狀況") {
            
            Stepper("疲勞程度：\(entry.fatigueScore)",
                    value: $entry.fatigueScore,
                    in: 0...10)
            
            ForEach(PainArea.allCases) { area in
                Toggle(area.rawValue,
                       isOn: Binding(
                        get: { entry.painAreas.contains(area) },
                        set: { isOn in
                            if isOn {
                                entry.painAreas.insert(area)
                                entry.painScoreByArea[area] = 5
                            } else {
                                entry.painAreas.remove(area)
                                entry.painScoreByArea.removeValue(forKey: area)
                            }
                        }
                       ))
                
                if entry.painAreas.contains(area) {
                    Stepper("疼痛程度：\(entry.painScoreByArea[area] ?? 0)",
                            value: Binding(
                                get: { entry.painScoreByArea[area] ?? 0 },
                                set: { entry.painScoreByArea[area] = $0 }
                            ),
                            in: 0...10)
                }
            }
        }
    }
}


// MARK: - 備註
struct NoteSection: View {
    @Binding var entry: DailyLogEntry
    
    var body: some View {
        Section("特別觀察到的事情") {
            TextEditor(text: $entry.specialObservation)
                .frame(minHeight: 180)
        }
    }
}
