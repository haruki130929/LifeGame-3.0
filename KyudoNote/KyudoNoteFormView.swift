import SwiftUI

struct KyudoNoteFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = KyudoNoteViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("1. 日期")) {
                    DatePicker("日期", selection: $vm.note.date, displayedComponents: .date)
                }
                
                Section(header: Text("2. 今天的練習菜單")) {
                    textEditorRow(text: $vm.note.practiceMenu, placeholder: "例：巻藁 20射 / 立射 10射…")
                }
                
                Section(header: Text("3. 今天的目標")) {
                    textEditorRow(text: $vm.note.todayGoal, placeholder: "例：離れ乾淨、節奏穩定…")
                }
                
                Section(header: Text("4. 特別注意的事項")) {
                    textEditorRow(text: $vm.note.specialFocus, placeholder: "例：大三肩線、呼吸節奏…")
                }
                
                Section(header: Text("5. 被指導的地方")) {
                    textEditorRow(text: $vm.note.coachedPoints, placeholder: "例：押手方向、會の伸合い…")
                }
                
                Section(header: Text("6. 下次的目標")) {
                    textEditorRow(text: $vm.note.nextGoal, placeholder: "例：把今天修正點重複練習…")
                }
                
                Section(header: Text("7. 今天發生的事情（弓道相關）")) {
                    textEditorRow(text: $vm.note.todaysStory, placeholder: "例：道場狀況、器材、心情…")
                }
                
                Section(header: Text("8. 中靶率 & 射到的地方")) {
                    Text("靶（點一下新增命中點）")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    KyudoTargetView(hits: vm.note.hits) { nx, ny in
                        vm.addHit(normalizedX: nx, normalizedY: ny)
                    }
                    .frame(height: 260)
                    .listRowInsets(EdgeInsets()) // 讓靶更滿一點（不一定每版都有效）
                    
                    HStack {
                        Button {
                            vm.removeLastHit()
                        } label: {
                            Label("撤銷", systemImage: "arrow.uturn.backward")
                        }
                        
                        Spacer()
                        
                        Button(role: .destructive) {
                            vm.clearHits()
                        } label: {
                            Label("清空", systemImage: "trash")
                        }
                    }
                    
                    HStack {
                        Text("中靶率")
                        Spacer()
                        Text(vm.hitRateText)
                            .bold()
                    }
                    Text("射數：\(vm.totalShots)（靶內：\(vm.hitsInsideTargetCount)）")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Section(header: Text("9. 從命中分佈得到的發現")) {
                    textEditorRow(text: $vm.note.insightsFromHits, placeholder: "例：多偏右上→可能押手/離れ…")
                }
            }
            .navigationTitle("弓道筆記")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        // 先不存檔，下一步再做
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func textEditorRow(text: Binding<String>, placeholder: String) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                    .padding(.leading, 5)
            }
            TextEditor(text: text)
                .frame(minHeight: 90)
        }
    }
}
