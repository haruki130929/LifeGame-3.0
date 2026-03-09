import SwiftUI

struct AddCalendarEventView: View {
    @ObservedObject var store: CalendarStore
    let calendar: Calendar
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var start: Date = .now
    @State private var end: Date = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
    
    var body: some View {
        NavigationStack {
            Form {
                Section("事件") {
                    TextField("標題", text: $title)
                }
                
                Section("時間") {
                    DatePicker("開始", selection: $start, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("結束", selection: $end, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("新增事件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("加入") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        guard end >= start else { return }
                        
                        Task {
                            await store.add(title: trimmed, start: start, end: end)
                            dismiss()
                        }
                    }
                }
            }
            .onChange(of: start) { _, newValue in
                if end < newValue {
                    end = calendar.date(byAdding: .hour, value: 1, to: newValue) ?? newValue
                }
            }
        }
    }
}
