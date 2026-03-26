import SwiftUI

struct NewEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var start: Date = Date()
    @State private var end: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    
    let onSave: (String, Date, Date) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("標題", text: $title)
                DatePicker("開始", selection: $start)
                DatePicker("結束", selection: $end)
            }
            .navigationTitle("新增行程")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty else { return }
                        onSave(t, start, end)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditEventSheet: View {
    @Environment(\.dismiss) private var dismiss

    let event: CalendarEvent
    let onSave: (String, Date, Date) -> Void
    var onDelete: (() -> Void)? = nil

    @State private var title: String
    @State private var start: Date
    @State private var end: Date
    @State private var showDeleteConfirmation = false

    init(event: CalendarEvent, onSave: @escaping (String, Date, Date) -> Void, onDelete: (() -> Void)? = nil) {
        self.event = event
        self.onSave = onSave
        self.onDelete = onDelete
        _title = State(initialValue: event.title)
        _start = State(initialValue: event.start)
        _end = State(initialValue: event.end)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("標題", text: $title)
                DatePicker("開始", selection: $start)
                DatePicker("結束", selection: $end)

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("刪除這個行程", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("編輯行程")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty else { return }
                        onSave(t, start, end)
                        dismiss()
                    }
                }
            }
            .confirmationDialog("確定要刪除「\(event.title)」嗎？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("刪除", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            }
        }
    }
}
