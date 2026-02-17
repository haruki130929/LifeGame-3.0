import SwiftUI

struct CalendarEventEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var calendarStore: CalendarStore
    
    let existing: CalendarEvent?           // nil = 新增，有值 = 編輯
    let defaultDay: Date                   // 新增時用來預設日期
    
    @State private var title: String = ""
    @State private var start: Date = Date()
    @State private var end: Date = Date()
    
    private let cal = Calendar.current
    
    init(existing: CalendarEvent?, defaultDay: Date) {
        self.existing = existing
        self.defaultDay = defaultDay
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("標題") {
                    TextField("例如：日文課 / 交作業 / 看醫生", text: $title)
                }
                
                Section("時間") {
                    DatePicker("開始", selection: $start, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("結束", selection: $end, displayedComponents: [.date, .hourAndMinute])
                }
                
                if existing != nil {
                    Section {
                        Button(role: .destructive) {
                            if let e = existing,
                               let idx = calendarStore.events.firstIndex(where: { $0.id == e.id }) {
                                calendarStore.events.remove(at: idx)
                                dismiss()
                            }
                        } label: {
                            Text("刪除這個行程")
                        }
                    }
                }
            }
            .navigationTitle(existing == nil ? "新增行程" : "編輯行程")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        save()
                    }
                    .disabled(titleTrimmed.isEmpty)
                }
            }
            .onAppear {
                prepareInitialValues()
            }
        }
    }
    
    private var titleTrimmed: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func prepareInitialValues() {
        if let e = existing {
            title = e.title
            start = e.start
            end = e.end
            return
        }
        
        // 新增：預設在 defaultDay 的「現在時刻」，結束 + 1 小時
        let now = Date()
        let day = defaultDay
        
        // 把日期改成 defaultDay，時間取 now（看起來比較自然）
        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        
        start = cal.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        end = cal.date(byAdding: .hour, value: 1, to: start) ?? start
    }
    
    private func save() {
        let fixedEnd: Date = (end <= start)
        ? (cal.date(byAdding: .hour, value: 1, to: start) ?? start)
        : end
        
        let finalTitle = titleTrimmed.isEmpty ? "未命名行程" : titleTrimmed
        
        if var e = existing {
            e.title = finalTitle
            e.start = start
            e.end = fixedEnd
            calendarStore.update(e)
        } else {
            calendarStore.add(title: finalTitle, start: start, end: fixedEnd)
        }
        
        dismiss()
    }
}
