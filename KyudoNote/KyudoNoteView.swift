import SwiftUI

struct KyudoNoteView: View {
    @StateObject private var vm = KyudoNoteViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    
                    sectionCard(title: "基本") {
                        HStack {
                            Text("日期").font(.headline)
                            Spacer()
                            DatePicker("", selection: $vm.note.date, displayedComponents: .date)
                                .labelsHidden()
                        }
                        .padding(.vertical, 6)
                        
                        editor(title: "今天的練習菜單", text: $vm.note.practiceMenu, placeholder: "例：巻藁 20射 / 立射 10射…")
                        editor(title: "今天的目標", text: $vm.note.todayGoal, placeholder: "例：放箭節奏穩定、離れ乾淨…")
                    }
                    
                    sectionCard(title: "練習筆記") {
                        editor(title: "為了達成目標，特別注意的事項", text: $vm.note.specialFocus, placeholder: "例：大三時肩線保持、呼吸節奏…")
                        editor(title: "被指導的地方", text: $vm.note.coachedPoints, placeholder: "例：押手、會の伸合い…")
                        editor(title: "下次的目標", text: $vm.note.nextGoal, placeholder: "例：今天修正點再重複練習…")
                        editor(title: "今天發生的事情（弓道相關）", text: $vm.note.todaysStory, placeholder: "例：新弦、道場狀況、心情…")
                    }
                    
                    sectionCard(title: "中靶與分佈") {
                        HStack {
                            Text("靶（點一下新增命中點）").font(.headline)
                            Spacer()
                            Text("紅點＝命中")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        
                        KyudoTargetView(hits: vm.note.hits) { nx, ny in
                            vm.addHit(normalizedX: nx, normalizedY: ny)
                        }
                        .frame(height: 280)
                        
                        HStack(spacing: 10) {
                            Button {
                                vm.removeLastHit()
                            } label: {
                                Label("撤銷最後一箭", systemImage: "arrow.uturn.backward")
                            }
                            .buttonStyle(.bordered)
                            
                            Button(role: .destructive) {
                                vm.clearHits()
                            } label: {
                                Label("清空", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        
                        HStack {
                            Text("中靶率").font(.headline)
                            Spacer()
                            Text(vm.hitRateText).font(.headline)
                        }
                        Text("射數：\(vm.totalShots)（靶內：\(vm.hitsInsideTargetCount)）")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    sectionCard(title: "從命中分佈得到的發見") {
                        editor(title: "從射中的地方、中靶率所發現的事情",
                               text: $vm.note.insightsFromHits,
                               placeholder: "例：點多偏右上→可能押手方向/離れ…")
                    }
                }
                .padding(12)
            }
            .navigationTitle("弓道筆記")
        }
    }
    
    // MARK: - Small UI helpers
    
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.title3.bold())
            content()
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private func editor(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            
            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.secondary)
                        .padding(.top, 10)
                        .padding(.leading, 6)
                }
                
                TextEditor(text: text)
                    .frame(minHeight: 90)
                    .padding(4)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.gray.opacity(0.25))
            )
        }
    }
}
