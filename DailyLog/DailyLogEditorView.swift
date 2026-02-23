import SwiftUI

struct DailyLogEditorView: View {
    let entry: DailyLogEntry
    let onSave: (DailyLogEntry) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var draft: DailyLogEntry
    
    init(entry: DailyLogEntry, onSave: @escaping (DailyLogEntry) -> Void) {
        self.entry = entry
        self.onSave = onSave
        _draft = State(initialValue: entry)
    }
    
    var body: some View {
        DailyLogFormView(entry: $draft)
            .navigationTitle("每日紀錄")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        onSave(draft)
                        dismiss()
                    }
                }
            }
    }
}
