import SwiftUI

struct KyudoNoteEditorView: View {
    enum Mode {
        case add
        case edit(KyudoNote)
    }
    
    let mode: Mode
    @ObservedObject var store: KyudoNoteStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var note = KyudoNote()
    
    private var title: String {
        switch mode {
        case .add: return "新增弓道筆記"
        case .edit: return "編輯弓道筆記"
        }
    }
    
    var body: some View {
        Form {
            // 1. 日期
            Section("1. 日期") {
                DatePicker("日期", selection: $note.date, displayedComponents: .date)
            }
            
            // 2. 今日練習菜單
            Section("2. 今日練習菜單") {
                TextField("例如：巻藁、立射、八節…", text: $note.practiceMenu, axis: .vertical)
                    .lineLimit(2...5)
            }
            
            // 3. 今日目標
            Section("3. 今日目標") {
                TextField("例如：放箭穩定、會 2/8…", text: $note.todayGoal, axis: .vertical)
                    .lineLimit(2...5)
            }
            
            // 4. 注意的事情
            Section("4. 為了達成目標所注意的事情") {
                TextField("例如：肩線、押手、呼吸…", text: $note.focusPoints, axis: .vertical)
                    .lineLimit(3...8)
            }
            
            // 5. 被指導的地方
            Section("5. 被指導的地方") {
                TextField("例如：大三角度、離れ timing…", text: $note.coachedPoints, axis: .vertical)
                    .lineLimit(3...8)
            }
            
            // 6. 下次的目標
            Section("6. 下次的目標") {
                TextField("例如：保持會、狙い一致…", text: $note.nextGoal, axis: .vertical)
                    .lineLimit(2...6)
            }
            
            // 7. 今天發生的事情
            Section("7. 今天發生的事情（跟弓道相關）") {
                TextField("例如：弓具狀態、身體狀況、比賽…", text: $note.todayHappened, axis: .vertical)
                    .lineLimit(3...8)
            }
            
            // 8. 靶 + 落點 + 中靶率
            Section("8. 射中的地方、中靶率") {
                TargetView(shots: $note.shots, hitRadius: note.hitRadius)
                
                HStack {
                    Text("中靶判定半徑")
                    Spacer()
                    Text("\(Int(note.hitRadius * 100))%")
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $note.hitRadius, in: 0.08...0.35, step: 0.01)
            }
            
            // 9. 根據落點的發現
            Section("9. 根據射中的地方所發現的事情") {
                TextField("例如：偏右上＝押手、離れ…", text: $note.findingsFromShots, axis: .vertical)
                    .lineLimit(3...8)
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                    dismiss()
                }
            }
        }
        .onAppear {
            switch mode {
            case .add:
                note = KyudoNote()
            case .edit(let existing):
                note = existing
            }
        }
    }
    
    private func save() {
        switch mode {
        case .add:
            store.add(note)
        case .edit:
            store.update(note)
        }
    }
}
