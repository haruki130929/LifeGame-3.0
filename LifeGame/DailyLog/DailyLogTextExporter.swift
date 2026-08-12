import Foundation

/// 把每日紀錄序列化成純文字（內容對應 DailyLogFullReviewCard 的檢視畫面，含自訂模組）。
@MainActor
struct DailyLogTextExporter {
    let moduleStore: QuestionModuleStore

    // MARK: - 對外入口

    func makeText(for entries: [DailyLogEntry], rangeTitle: String) -> String {
        var out = String(localized: "每日紀錄匯出\n")
        out += "\(rangeTitle)\n"
        out += String(localized: "共 \(entries.count) 筆\n")
        out += String(repeating: "=", count: 32) + "\n\n"

        let sorted = entries.sorted { $0.date < $1.date }
        for entry in sorted {
            out += entryText(entry)
            out += "\n" + String(repeating: "-", count: 32) + "\n\n"
        }
        return out
    }

    // MARK: - 單筆

    private func entryText(_ entry: DailyLogEntry) -> String {
        var lines: [String] = []

        // 標題
        lines.append(String(localized: "【\(dateText(entry.date))】　天氣：\(entry.weather.displayName)"))
        lines.append("")

        func append(_ block: [String]) {
            guard !block.isEmpty else { return }
            lines.append(contentsOf: block)
            lines.append("")
        }

        append(sectionLines(for: .basic, entry: entry, hardcoded: basicBlock(entry)))

        // 情緒：moodMental + moodChange，未自訂時用合併硬編碼版
        if !isCustomized(.moodMental) && !isCustomized(.moodChange) {
            append(moodBlock(entry))
        } else {
            append(sectionLinesCustomOnly(for: .moodMental, entry: entry))
            append(sectionLinesCustomOnly(for: .moodChange, entry: entry))
        }

        append(sectionLines(for: .anxiety, entry: entry, hardcoded: anxietyBlock(entry)))
        append(sectionLines(for: .impulse, entry: entry, hardcoded: impulseBlock(entry)))
        append(sectionLines(for: .sleep, entry: entry, hardcoded: sleepBlock(entry)))
        append(sectionLines(for: .studyFocus, entry: entry, hardcoded: studyBlock(entry)))
        append(sectionLines(for: .body, entry: entry, hardcoded: bodyBlock(entry)))
        append(sectionLines(for: .observation, entry: entry, hardcoded: observationBlock(entry)))

        // 自訂模組
        for module in moduleStore.enabledCustomModules {
            append(customModuleLines(module: module, entry: entry))
        }

        // 照片
        if !entry.photos.isEmpty {
            var block = [String(localized: "照片（\(entry.photos.count)）")]
            for (i, p) in entry.photos.enumerated() {
                let caption = p.caption.trimmingCharacters(in: .whitespacesAndNewlines)
                block.append("  ［\(i + 1)］\(caption.isEmpty ? "（無說明）" : caption)")
            }
            append(block)
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - 內建區塊（純文字版，對應卡片）

    private func basicBlock(_ e: DailyLogEntry) -> [String] {
        [String(localized: "基本"),
         String(localized: "  起床：\(timeText(e.wakeTime))"),
         String(localized: "  上床：\(timeText(e.bedTime))")]
    }

    private func moodBlock(_ e: DailyLogEntry) -> [String] {
        var lines = [String(localized: "情緒與心理狀態"),
                     String(localized: "  情緒 \(e.overallMoodScore)/10、焦慮 \(e.anxietyScore)/10、疲勞 \(e.fatigueScore)/10")]
        if e.moodChangeType == .higher {
            lines.append(String(localized: "  情緒變化：變高"))
            if !e.moodChangeReasons.isEmpty {
                lines.append(String(localized: "  原因：\(join(e.moodChangeReasons.map{$0.displayName}, otherText: e.moodChangeReasons.contains(.other) ? e.moodChangeOtherText : ""))"))
            }
            if !e.moodChangeDurationText.isEmpty {
                lines.append(String(localized: "  持續時間：\(e.moodChangeDurationText)"))
            }
            if !e.stabilizeMethodsForMoodChange.isEmpty {
                lines.append(String(localized: "  穩定方式：\(join(e.stabilizeMethodsForMoodChange.map{$0.displayName}, otherText: e.stabilizeMethodsForMoodChange.contains(.other) ? e.stabilizeOtherTextForMoodChange : ""))"))
            }
        } else {
            lines.append(String(localized: "  情緒變化：穩定"))
        }
        return lines
    }

    private func anxietyBlock(_ e: DailyLogEntry) -> [String] {
        var lines = [String(localized: "是否出現焦慮"),
                     String(localized: "  程度：\(e.anxietyLevel.rawValue)")]
        if e.anxietyLevel != .none {
            if !e.anxietyReasons.isEmpty {
                lines.append(String(localized: "  原因：\(join(e.anxietyReasons.map{$0.displayName}, otherText: e.anxietyReasons.contains(.other) ? e.anxietyOtherText : ""))"))
            }
            if !e.anxietyDurationText.isEmpty {
                lines.append(String(localized: "  持續時間：\(e.anxietyDurationText)"))
            }
            if !e.anxietySymptoms.isEmpty {
                lines.append(String(localized: "  表現：\(join(e.anxietySymptoms.map{$0.displayName}, otherText: e.anxietySymptoms.contains(.other) ? e.anxietySymptomOtherText : ""))"))
            }
            if !e.stabilizeMethodsForAnxiety.isEmpty {
                lines.append(String(localized: "  穩定方式：\(join(e.stabilizeMethodsForAnxiety.map{$0.displayName}, otherText: e.stabilizeMethodsForAnxiety.contains(.other) ? e.stabilizeOtherTextForAnxiety : ""))"))
            }
        }
        return lines
    }

    private func impulseBlock(_ e: DailyLogEntry) -> [String] {
        var lines = [String(localized: "衝動行為")]
        if e.impulseSeverities.isEmpty {
            lines.append(String(localized: "  無"))
        } else {
            for sev in e.impulseSeverities.sorted(by: { $0.rawValue < $1.rawValue }) {
                let set = e.impulseTypesBySeverity[sev] ?? []
                let names = set.map { $0.rawValue }
                let other = set.contains(.other) ? (e.impulseOtherTextBySeverity[sev] ?? "") : ""
                lines.append("  \(sev.displayName)：\(join(names, otherText: other))")
            }
        }
        return lines
    }

    private func sleepBlock(_ e: DailyLogEntry) -> [String] {
        [String(localized: "睡眠狀況"),
         String(localized: "  入睡所需時間：\(e.sleepLatency.rawValue)"),
         String(localized: "  睡眠時長：\(sleepHoursText(e))"),
         String(localized: "  睡眠品質：\(e.sleepQuality.shortDisplayName)")]
    }

    private func studyBlock(_ e: DailyLogEntry) -> [String] {
        var lines = [String(localized: "課業與專注力"),
                     String(localized: "  待辦完成：\(e.todoCompletion.rawValue)")]
        if e.todoCompletion == .partial {
            lines.append(String(localized: "  部分完成：\(e.todoPartialDone)/\(e.todoPartialTotal) 項"))
        }
        lines.append(String(localized: "  專注度：\(e.focusQuality.displayName)"))
        if e.focusQuality == .cannotFocus, !e.cannotFocusReasons.isEmpty {
            lines.append(String(localized: "  可能原因：\(join(e.cannotFocusReasons.map{$0.displayName}, otherText: e.cannotFocusReasons.contains(.other) ? e.cannotFocusOtherText : ""))"))
        }
        if e.unfinished {
            lines.append(String(localized: "  未完成：\(e.unfinishedCount)/\(e.unfinishedTotal) 項"))
            if !e.difficultyReasons.isEmpty {
                lines.append(String(localized: "  困難：\(join(e.difficultyReasons.map{$0.displayName}, otherText: e.difficultyReasons.contains(.other) ? e.difficultyOtherText : ""))"))
            }
        } else {
            lines.append(String(localized: "  未完成事項：無"))
        }
        return lines
    }

    private func bodyBlock(_ e: DailyLogEntry) -> [String] {
        var lines = [String(localized: "身體狀況")]
        if e.painAreas.isEmpty {
            lines.append(String(localized: "  不適：無"))
        } else {
            let list = e.painAreas.map { area -> String in
                let score = e.painScoreByArea[area] ?? 1
                return "\(area.rawValue)（\(score)/10）"
            }
            lines.append(String(localized: "  不適：\(list.joined(separator: "、"))"))
        }
        lines.append(String(localized: "  注意到身體狀況：\(e.bodyNoticeTiming.displayName)"))
        if e.bodyNoticeTiming == .none, !e.bodyLateReasons.isEmpty {
            lines.append(String(localized: "  原因：\(join(e.bodyLateReasons.map{$0.displayName}, otherText: e.bodyLateReasons.contains(.other) ? e.bodyLateOtherText : ""))"))
        }
        return lines
    }

    private func observationBlock(_ e: DailyLogEntry) -> [String] {
        let obs = e.specialObservation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !obs.isEmpty else { return [] }
        return [String(localized: "特別觀察"), "  \(obs)"]
    }

    // MARK: - 自訂模組

    private func isCustomized(_ kind: ModuleKind) -> Bool {
        guard let module = moduleStore.modules.first(where: { $0.kind == kind }) else { return false }
        return !(module.questions?.isEmpty ?? true)
    }

    private func sectionLines(for kind: ModuleKind, entry: DailyLogEntry, hardcoded: [String]) -> [String] {
        if isCustomized(kind), let module = moduleStore.modules.first(where: { $0.kind == kind }) {
            return customModuleLines(module: module, entry: entry)
        }
        return hardcoded
    }

    private func sectionLinesCustomOnly(for kind: ModuleKind, entry: DailyLogEntry) -> [String] {
        if isCustomized(kind), let module = moduleStore.modules.first(where: { $0.kind == kind }) {
            return customModuleLines(module: module, entry: entry)
        }
        return []
    }

    private func customModuleLines(module: DailyLogModule, entry: DailyLogEntry) -> [String] {
        var lines = [module.displayTitle]
        for q in module.displayQuestions {
            guard let answer = entry.customAnswers.first(where: { $0.questionId == q.id }) else { continue }
            lines.append(contentsOf: answerLines(question: q, answer: answer).map { "  " + $0 })
        }
        // 只有標題沒有內容時不輸出
        return lines.count > 1 ? lines : []
    }

    private func answerLines(question q: QuestionDefinition, answer: CustomAnswer) -> [String] {
        switch q.type {
        case .slider, .numberInput:
            if let v = answer.intValue { return ["\(q.title)：\(v)"] }
        case .singleSelect:
            if let v = answer.stringValue, !v.isEmpty {
                var suffix = ""
                if v == "其他", let o = answer.otherText, !o.isEmpty { suffix = "（\(o)）" }
                return ["\(q.title)：\(v)\(suffix)"]
            }
        case .multiSelect:
            if let arr = answer.stringArrayValue, !arr.isEmpty {
                return ["\(q.title)：\(joinCustom(arr, otherText: answer.otherText ?? ""))"]
            }
        case .freeText:
            if let v = answer.stringValue, !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return ["\(q.title)：\(v)"]
            }
        case .timePicker:
            if let d = answer.dateValue {
                return ["\(q.title)：\(d.formatted(date: .omitted, time: .shortened))"]
            }
        case .nestedMultiSelect:
            if let nested = answer.nestedValue {
                var out: [String] = []
                for group in nested.keys.sorted() {
                    if let items = nested[group], !items.isEmpty {
                        let otherText = answer.nestedOtherText?[group] ?? ""
                        out.append("\(group)：\(joinCustom(items, otherText: otherText))")
                    }
                }
                return out
            }
        case .photo:
            return []
        }
        return []
    }

    // MARK: - Helpers

    private func dateText(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.setLocalizedDateFormatFromTemplate("yMMMMdEEE")
        return fmt.string(from: date)
    }

    private func timeText(_ t: OptionalLogTime) -> String {
        switch t {
        case .unknown: return String(localized: "忘記")
        case .time(let d): return d.formatted(date: .omitted, time: .shortened)
        }
    }

    private func sleepHoursText(_ e: DailyLogEntry) -> String {
        switch e.sleepHours {
        case .unknown: return String(localized: "忘記")
        case .value(let h): return String(localized: "\(String(format: "%.1f", h)) 小時")
        }
    }

    private func join(_ items: [String], otherText: String) -> String {
        let trimmed = otherText.trimmingCharacters(in: .whitespacesAndNewlines)
        // items 可能是 enum 的 displayName（已在地化）或使用者資料裡的原始字串（永遠是「其他」），
        // 兩種都要認得，否則切到英文/日文時「其他」會篩不掉。
        let otherLabel = String(localized: "其他")
        let isOther: (String) -> Bool = { $0 == otherLabel || $0 == "其他" }
        var base = items.filter { !isOther($0) }
        if items.contains(where: isOther), !trimmed.isEmpty {
            base.append(String(localized: "其他：\(trimmed)"))
        } else if items.contains(where: isOther) {
            base.append(otherLabel)
        }
        return base.isEmpty ? "--" : base.joined(separator: String(localized: "、"))
    }

    private func joinCustom(_ items: [String], otherText: String) -> String {
        join(items, otherText: otherText)
    }
}
