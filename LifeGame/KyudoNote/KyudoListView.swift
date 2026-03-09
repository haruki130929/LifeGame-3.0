import SwiftUI

struct KyudoNoteListView: View {
    @StateObject private var store = KyudoNoteStore()
    @State private var showingAdd = false
    
    var body: some View {
        List {
            if store.notes.isEmpty {
                ContentUnavailableView("還沒有筆記",
                                       systemImage: "book",
                                       description: Text("按右下角 ＋ 新增第一篇弓道筆記"))
            } else {
                ForEach(store.notes) { note in
                    NavigationLink {
                        KyudoNoteEditorView(mode: .edit(note), store: store)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.date, format: .dateTime.year().month().day())
                                .font(.headline)
                            
                            if !note.todayGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("目標：\(note.todayGoal)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            
                            let rate = KyudoMath.hitRatePercent(shots: note.shots, hitRadius: note.hitRadius)
                            Text("落點：\(note.shots.count) 發｜中靶率：\(rate)%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: store.delete)
            }
        }
        .navigationTitle("弓道筆記")
        // ✅ 用你全域 FAB（右下角 +）
        .fabMenu([
            FabAction(title: "新增弓道筆記", systemImage: "plus") {
                showingAdd = true
            }
        ])
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                KyudoNoteEditorView(mode: .add, store: store)
            }
        }
    }
}
