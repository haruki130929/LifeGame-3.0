import SwiftUI

struct Key3EditorView: View {
    @ObservedObject var store: Key3Store
    
    @State private var purpose = ""
    @State private var t1 = ""
    @State private var t2 = ""
    @State private var t3 = ""
    
    private var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    }
    
    var body: some View {
        Form {
            Section("明天的目的") {
                TextField("一句話目的", text: $purpose)
            }
            
            Section("三件關鍵事") {
                TextField("關鍵任務 1", text: $t1)
                TextField("關鍵任務 2", text: $t2)
                TextField("關鍵任務 3", text: $t3)
            }
            
            Button("儲存") { save() }
                .disabled(!canSave)
        }
        .navigationTitle("明天三件關鍵事")
        .onAppear { load() }
    }
    
    private var canSave: Bool {
        !purpose.isEmpty && !t1.isEmpty && !t2.isEmpty && !t3.isEmpty
    }
    
    private func save() {
        let key = store.dateKeyString(tomorrow)
        let plan = Key3Plan(
            dateKey: key,
            purpose: purpose,
            tasks: [KeyTask(title: t1), KeyTask(title: t2), KeyTask(title: t3)],
            activeTaskID: nil,
            updatedAt: Date()
        )
        store.upsert(plan)
    }
    
    private func load() {
        guard let p = store.plan(for: tomorrow) else { return }
        purpose = p.purpose
        t1 = p.tasks[safe: 0]?.title ?? ""
        t2 = p.tasks[safe: 1]?.title ?? ""
        t3 = p.tasks[safe: 2]?.title ?? ""
    }
}

private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
