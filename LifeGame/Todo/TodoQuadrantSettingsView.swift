import SwiftUI

struct TodoQuadrantSettingsView: View {
    @EnvironmentObject private var store: TodoQuadrantStore

    var body: some View {
        Form {
            Section {
                let doneCount = store.items.filter(\.isDone).count
                Button(role: .destructive) {
                    store.items.removeAll { $0.isDone }
                } label: {
                    HStack {
                        Text("清除已完成的待辦")
                        Spacer()
                        Text("\(doneCount) 筆")
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(doneCount == 0)
            } header: {
                Text("資料管理")
            } footer: {
                Text("清除後無法復原")
            }

            Section("統計") {
                HStack {
                    Text("總待辦數")
                    Spacer()
                    Text("\(store.items.count)")
                        .foregroundStyle(.secondary)
                }
                ForEach(TodoQuadrant.allCases) { q in
                    HStack {
                        Text(q.title)
                        Spacer()
                        let total = store.items(in: q).count
                        let done = store.items(in: q).filter(\.isDone).count
                        Text("\(done)/\(total)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("待辦四象限設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}
