import SwiftUI

struct DiaryView: View {
    @StateObject private var store = DiaryStore()
    @EnvironmentObject private var fab: FabStore
    @State private var showingAdd = false

    var body: some View {
        List {
            if store.entries.isEmpty {
                ContentUnavailableView("還沒有日記",
                                       systemImage: "book",
                                       description: Text("按右下角 ＋ 新增第一篇日記"))
            } else {
                ForEach(store.entries) { entry in
                    NavigationLink {
                        DiaryEditorView(mode: .edit(entry), store: store)
                            .hidesFab()
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.date, format: .dateTime.year().month().day())
                                .font(.headline)

                            if !entry.content.isEmpty {
                                Text(entry.content)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            if !entry.photos.isEmpty {
                                Label("\(entry.photos.count) 張照片", systemImage: "photo")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }

                            if !entry.answers.isEmpty {
                                Text("已填 \(entry.answers.count) 項")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: store.delete)
            }
        }
        .navigationTitle("日記")
        .fabMenu([
            FabAction(title: String(localized: "新增日記"), systemImage: "plus") {
                showingAdd = true
            },
            FabAction(title: String(localized: "設定"), systemImage: "gearshape") {
                fab.route = .featureSettings(.diary)
                fab.collapse()
            }
        ])
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                DiaryEditorView(mode: .add, store: store)
            }
        }
    }
}
