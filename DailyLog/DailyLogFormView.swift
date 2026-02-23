import SwiftUI

struct DailyLogFormView: View {
    @Binding var entry: DailyLogEntry
    
    var body: some View {
        Form {
            basicSection
            moodSection
            sleepSection
            studySection
            bodySection
            observationSection
        }
    }
}

// MARK: - Sections
private extension DailyLogFormView {
    
    var basicSection: some View {
        Section("基本") {
            DatePicker("日期", selection: $entry.date, displayedComponents: .date)
            
            Picker("天氣", selection: $entry.weather) {
                ForEach(Weather.allCases) { w in
                    Text(w.rawValue).tag(w)
                }
            }
            
            // 起床時間：可忘記 + 30 分鐘刻度
            HalfHourOptionalTimePickerRow(title: "起床時間", value: $entry.wakeTime)
            
            // 上床時間：30 分鐘刻度
            HalfHourOptionalTimePickerRow(title: "昨晚上床時間", value: $entry.bedTime)
        }
    }
    
    // ✅ 建議：把原本一個 Section 內塞一堆 VStack 小標，改成子 Section（最穩）
    var moodSection: some View {
        Group {
            Section("情緒與心理狀態") {
                ScoreSliderRow(title: "整體情緒分數", value: $entry.overallMoodScore)
                ScoreSliderRow(title: "焦慮程度", value: $entry.anxietyScore)
            }
            
            Section("情緒變化") {
                
                // 1) 狀態（單選 ⬜︎）
                CheckboxSingleSelectList(
                    title: "狀態（單選）",
                    options: MoodChangeType.allCases,
                    selection: $entry.moodChangeType
                )
                
                // 2) 只有「變高」才顯示細項
                if entry.moodChangeType == .higher {
                    
                    // 原因（多選 ⬜︎）
                    CheckboxMultiSelectList(
                        title: "原因（可複選）",
                        options: MoodChangeReason.allCases,
                        selected: $entry.moodChangeReasons
                    )
                    
                    // 其他原因填空
                    if entry.moodChangeReasons.contains(.other) {
                        TextField("其他原因（請填寫）", text: $entry.moodChangeOtherText)
                    }
                    
                    // 持續時間（填空）
                    TextField("持續時間", text: $entry.moodChangeDurationText)
                    
                    // 穩定方式（多選 ⬜︎）
                    CheckboxMultiSelectList(
                        title: "用什麼方式穩定下來（可複選）",
                        options: StabilizeMethod.allCases,
                        selected: $entry.stabilizeMethodsForMoodChange
                    )
                    
                    // 其他穩定方式填空
                    if entry.stabilizeMethodsForMoodChange.contains(.other) {
                        TextField("其他方式（請填寫）", text: $entry.stabilizeOtherTextForMoodChange)
                    }
                    
                } else {
                    Text("已選擇「穩定」")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("是否出現焦慮") {
                
                // 程度（單選 ⬜︎）
                CheckboxSingleSelectList(
                    title: "程度（單選）",
                    options: AnxietyLevel.allCases,
                    selection: $entry.anxietyLevel
                )
                
                if entry.anxietyLevel != .none {
                    
                    // 原因（多選 ⬜︎）
                    CheckboxMultiSelectList(
                        title: "原因（可複選）",
                        options: AnxietyReason.allCases,
                        selected: $entry.anxietyReasons
                    )
                    
                    if entry.anxietyReasons.contains(.other) {
                        TextField("其他原因（請填寫）", text: $entry.anxietyOtherText)
                    }
                    
                    // 持續時間（填空）
                    TextField("持續時間", text: $entry.anxietyDurationText)
                    
                    // 焦慮表現（多選 ⬜︎）
                    CheckboxMultiSelectList(
                        title: "焦慮表現（可複選）",
                        options: AnxietySymptom.allCases,
                        selected: $entry.anxietySymptoms
                    )
                    
                    if entry.anxietySymptoms.contains(.other) {
                        TextField("其他表現（請填寫）", text: $entry.anxietySymptomOtherText)
                    }
                    
                    // 穩定方式（多選 ⬜︎）
                    CheckboxMultiSelectList(
                        title: "用什麼方式穩定下來（可複選）",
                        options: StabilizeMethod.allCases,
                        selected: $entry.stabilizeMethodsForAnxiety
                    )
                    
                    if entry.stabilizeMethodsForAnxiety.contains(.other) {
                        TextField("其他方式（請填寫）", text: $entry.stabilizeOtherTextForAnxiety)
                    }
                } else {
                    Text("已選擇「無」")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("衝動行為") {
                
                // ✅ 「無」：只要勾了就清空其他
                CheckboxRow(
                    title: "無",
                    isChecked: Binding(
                        get: { entry.impulseSeverities.isEmpty },
                        set: { isOn in
                            if isOn {
                                entry.impulseSeverities.removeAll()
                                entry.impulseTypesBySeverity.removeAll()
                                entry.impulseOtherTextBySeverity.removeAll()
                            }
                        }
                    )
                )
                
                // ✅ 多選程度（輕微/中等/嚴重）
                VStack(alignment: .leading, spacing: 8) {
                    Text("程度（可複選）")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    ForEach(ImpulseSeverity.allCases) { sev in
                        CheckboxRow(
                            title: sev.rawValue,
                            isChecked: Binding(
                                get: { entry.impulseSeverities.contains(sev) },
                                set: { isOn in
                                    if isOn {
                                        entry.impulseSeverities.insert(sev)
                                    } else {
                                        entry.impulseSeverities.remove(sev)
                                        entry.impulseTypesBySeverity[sev] = nil
                                        entry.impulseOtherTextBySeverity[sev] = nil
                                    }
                                }
                            )
                        )
                        
                        // ✅ 勾了某個程度 → 顯示該程度的「衝動行為選項」
                        if entry.impulseSeverities.contains(sev) {
                            CheckboxMultiSelectList(
                                title: "\(sev.rawValue) 的衝動行為（可複選）",
                                options: ImpulseType.allCases,
                                selected: Binding(
                                    get: { entry.impulseTypesBySeverity[sev] ?? [] },
                                    set: { entry.impulseTypesBySeverity[sev] = $0 }
                                )
                            )
                            
                            // 其他（填空）
                            let selectedSet = entry.impulseTypesBySeverity[sev] ?? []
                            if selectedSet.contains(.other) {
                                TextField(
                                    "其他（請填寫）",
                                    text: Binding(
                                        get: { entry.impulseOtherTextBySeverity[sev] ?? "" },
                                        set: { entry.impulseOtherTextBySeverity[sev] = $0 }
                                    )
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    var sleepSection: some View {
        Section("睡眠狀況") {
            
            // ⬜︎ 單選：入睡所需時間
            CheckboxSingleSelectList(
                title: "入睡所需時間（單選）",
                options: SleepLatency.allCases,
                selection: $entry.sleepLatency
            )
            
            // 睡眠時長：先維持你原本的 0.5 單位 wheel（這不是勾選題）
            OptionalHalfHourNumberPickerRow(
                title: "睡眠時長（小時）",
                value: $entry.sleepHours,
                range: 0...16
            )
            
            // ⬜︎ 單選：睡眠品質（文字很長也沒問題，會同列內換行）
            CheckboxSingleSelectList(
                title: "睡眠品質（單選）",
                options: SleepQuality.allCases,
                selection: $entry.sleepQuality
            )
        }
    }
    
    var studySection: some View {
        Section("課業與專注力") {
            
            // 1) 是否完成今日待辦事項（單選 ⬜︎）
            CheckboxSingleSelectList(
                title: "是否完成今日待辦事項（單選）",
                options: TodoCompletion.allCases,
                selection: $entry.todoCompletion
            )
            
            if entry.todoCompletion == .partial {
                HStack {
                    Text("部分完成")
                    Spacer()
                    
                    TextField("完成", value: $entry.todoPartialDone, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    
                    Text("/")
                    
                    TextField("總數", value: $entry.todoPartialTotal, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    
                    Text("項")
                }
            }
            
            // 2) 今日專注度（單選 ⬜︎）
            CheckboxSingleSelectList(
                title: "今日專注度（單選）",
                options: FocusQuality.allCases,
                selection: $entry.focusQuality
            )
            
            if entry.focusQuality == .cannotFocus {
                // 可能原因（多選 ⬜︎）
                CheckboxMultiSelectList(
                    title: "可能原因（可複選）",
                    options: CannotFocusReason.allCases,
                    selected: $entry.cannotFocusReasons
                )
                
                if entry.cannotFocusReasons.contains(.other) {
                    TextField("其他原因（請填寫）", text: $entry.cannotFocusOtherText)
                }
            }
            
            // 3) 今日未完成事項（單選 ⬜︎：無 / 有）
            // 你 model 目前是 Bool：unfinished
            // 我們用兩個 CheckboxRow 來做「單選效果」
            VStack(alignment: .leading, spacing: 8) {
                Text("今日未完成事項（單選）")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                CheckboxRow(
                    title: "無",
                    isChecked: Binding(
                        get: { entry.unfinished == false },
                        set: { isOn in if isOn { entry.unfinished = false } }
                    )
                )
                
                CheckboxRow(
                    title: "有",
                    isChecked: Binding(
                        get: { entry.unfinished == true },
                        set: { isOn in if isOn { entry.unfinished = true } }
                    )
                )
            }
            
            if entry.unfinished {
                HStack {
                    Text("未完成")
                    Spacer()
                    
                    TextField("未完成", value: $entry.unfinishedCount, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    
                    Text("/")
                    
                    TextField("總數", value: $entry.unfinishedTotal, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    
                    Text("項")
                }
                
                // 遇到的困難（多選 ⬜︎）
                CheckboxMultiSelectList(
                    title: "遇到的困難（可複選）",
                    options: DifficultyReason.allCases,
                    selected: $entry.difficultyReasons
                )
                
                if entry.difficultyReasons.contains(.other) {
                    TextField("其他困難（請填寫）", text: $entry.difficultyOtherText)
                }
            }
        }
    }
    
    var bodySection: some View {
        Section("身體狀況") {
            
            // 疲勞（不是⬜︎題，先保留 Slider）
            ScoreSliderRow(title: "今日疲勞程度", value: $entry.fatigueScore)
            
            // 疼痛的地方（⬜︎ 多選）
            VStack(alignment: .leading, spacing: 8) {
                Text("疼痛的地方（可複選）")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                ForEach(PainArea.allCases) { area in
                    CheckboxRow(
                        title: area.rawValue,
                        isChecked: bindingForSet($entry.painAreas, element: area)
                    )
                    
                    if entry.painAreas.contains(area) {
                        Picker("疼痛程度（1～10）", selection: bindingForPainScore(area)) {
                            ForEach(1...10, id: \.self) { v in
                                Text("\(v)").tag(v)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            
            // 是否注意到身體狀況（⬜︎ 單選）
            CheckboxSingleSelectList(
                title: "是否注意到身體的狀況（單選）",
                options: BodyNoticeTiming.allCases,
                selection: $entry.bodyNoticeTiming
            )
            
            // 若選「沒有」：原因（⬜︎ 多選 + 其他填空）
            if entry.bodyNoticeTiming == .none {
                CheckboxMultiSelectList(
                    title: "因為（可複選）",
                    options: BodyLateReason.allCases,
                    selected: $entry.bodyLateReasons
                )
                
                if entry.bodyLateReasons.contains(.other) {
                    TextField("其他原因（請填寫）", text: $entry.bodyLateOtherText)
                }
            }
        }
    }
    
    // MARK: - helpers（如果你檔案裡已經有同名 helper，就不要重複貼）
    // ✅ 你原本 DailyLogFormView 已經有 bindingForPainScore / bindingForSet 的話，這段不要重貼
    private func bindingForPainScore(_ area: PainArea) -> Binding<Int> {
        Binding(
            get: { entry.painScoreByArea[area] ?? 1 },
            set: { entry.painScoreByArea[area] = $0 }
        )
    }
    
    private func bindingForSet<T: Hashable>(_ set: Binding<Set<T>>, element: T) -> Binding<Bool> {
        Binding(
            get: { set.wrappedValue.contains(element) },
            set: { isOn in
                if isOn { set.wrappedValue.insert(element) }
                else { set.wrappedValue.remove(element) }
            }
        )
    }
    
    var observationSection: some View {
        Section("特別觀察到的事情") {
            TextEditor(text: $entry.specialObservation)
                .frame(minHeight: 120)
            
            DailyLogPhotosSection(photos: $entry.photos)
        }
    }
}
