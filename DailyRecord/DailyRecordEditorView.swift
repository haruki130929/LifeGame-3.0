import SwiftUI

struct DailyRecordEditorView: View {
    @ObservedObject var store: DailyRecordStore
    let date: Date
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var mood: Double = 5
    @State private var anxiety: Double = 5
    @State private var sleepHours: Double = 7
    @State private var focus: Double = 5
    @State private var note: String = ""
    
    var body: some View {
        Form {
            Section("日期") {
                Text(date.formatted(date: .complete, time: .omitted))
            }
            
            Section("量表") {
                Stepper("情緒：\(Int(mood))", value: $mood, in: 0...10, step: 1)
                Stepper("焦慮：\(Int(anxiety))", value: $anxiety, in: 0...10, step: 1)
                Stepper("專注：\(Int(focus))", value: $focus, in: 0...10, step: 1)
                
                HStack {
                    Text("睡眠（小時）")
                    Spacer()
                    Text(String(format: "%.1f", sleepHours))
                        .foregroundStyle(.secondary)
                }
                Slider(value: $sleepHours, in: 0...24, step: 0.5)
            }
            
            Section("備註") {
                TextEditor(text: $note)
                    .frame(minHeight: 120)
            }
            
            Section {
                Button(role: .destructive) {
                    store.delete(for: date)
                    dismiss()
                } label: {
                    Text("刪除這天的紀錄")
                }
            }
        }
        .navigationTitle("當日紀錄")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") {
                    let r = DailyRecord(
                        date: date,
                        mood: Int(mood),
                        anxiety: Int(anxiety),
                        sleepHours: sleepHours,
                        focus: Int(focus),
                        note: note
                    )
                    store.upsert(r)
                    dismiss()
                }
            }
        }
        .onAppear { loadIfExists() }
    }
    
    private func loadIfExists() {
        guard let r = store.record(for: date) else { return }
        mood = Double(r.mood)
        anxiety = Double(r.anxiety)
        sleepHours = r.sleepHours
        focus = Double(r.focus)
        note = r.note
    }
}
