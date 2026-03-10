import SwiftUI

// MARK: - Large Card（主畫面預覽）
struct TodoQuadrantCardLarge: View {
    @EnvironmentObject private var theme: ThemeStore
    @ObservedObject var store: TodoQuadrantStore
    
    // 善甯：如果卡片外觀有自己的容器，替換這裡最外層即可
    var body: some View {
        Button {
            // 用 NavigationLink 也可以，這裡用 button + sheet 比較不依賴架構
            showSheet = true
        } label: {
            cardBody
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                TodoQuadrantBoardView(store: store)
                    .navigationTitle("待辦四象限")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("關閉") { showSheet = false }
                        }
                    }
            }
        }
    }
    
    @State private var showSheet = false
    
    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("待辦四象限")
                    .font(.headline)
                Spacer()
            }
            
            // 2x2 四格預覽
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    quadrantPreviewCell(.importantNotUrgent)
                    quadrantPreviewCell(.importantUrgent)
                }
                HStack(spacing: 8) {
                    quadrantPreviewCell(.notImportantNotUrgent)
                    quadrantPreviewCell(.urgentNotImportant)
                }
            }
        }
        .padding(14)
        .background {
            if theme.isDark {
                RoundedRectangle(cornerRadius: 18).fill(.thinMaterial)
            } else {
                RoundedRectangle(cornerRadius: 18).fill(Color.white)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    theme.isDark
                        ? Color.white.opacity(0.06)
                        : Color.black.opacity(0.10),
                    lineWidth: 1
                )
        )
        .shadow(
            color: theme.isDark ? .black.opacity(0.3) : .black.opacity(0.08),
            radius: theme.isDark ? 10 : 8,
            x: 0,
            y: theme.isDark ? 6 : 3
        )
    }

    private func quadrantPreviewCell(_ q: TodoQuadrant) -> some View {
        let list = store.previewItems(in: q, limit: 2)

        return VStack(alignment: .leading, spacing: 6) {
            Text(q.title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if list.isEmpty {
                Text("--")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(list) { item in
                    previewRow(item)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .background {
            if theme.isDark {
                RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial)
            } else {
                RoundedRectangle(cornerRadius: 14).fill(Color(.systemGray6))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private func previewRow(_ item: TodoItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isDone ? AnyShapeStyle(.secondary) : AnyShapeStyle(theme.accentColor))
            
            Text(item.title)
                .font(.footnote)
                .lineLimit(1)
                .foregroundStyle(item.isDone ? .secondary : .primary)
                .strikethrough(item.isDone, color: .secondary)
        }
    }
}

// MARK: - 四象限完整頁
struct TodoQuadrantBoardView: View {
    @EnvironmentObject private var theme: ThemeStore
    @ObservedObject var store: TodoQuadrantStore
    
    // 新增先留著（之後接右下角 +）
    @State private var showAdd = false
    @State private var addTitle = ""
    @State private var addQuadrant: TodoQuadrant = .importantNotUrgent
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                
                axisHint
                
                // 2x2 Grid
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        quadrantCell(.importantNotUrgent)
                        quadrantCell(.importantUrgent)
                    }
                    HStack(spacing: 12) {
                        quadrantCell(.notImportantNotUrgent)
                        quadrantCell(.urgentNotImportant)
                    }
                }
            }
            .padding(14)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("新增") {
                    showAdd = true
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                Form {
                    Section("新增待辦") {
                        TextField("內容", text: $addTitle)
                        Picker("象限", selection: $addQuadrant) {
                            ForEach(TodoQuadrant.allCases) { q in
                                Text(q.title).tag(q)
                            }
                        }
                    }
                }
                .navigationTitle("新增待辦")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { showAdd = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("儲存") {
                            store.add(title: addTitle, quadrant: addQuadrant)
                            addTitle = ""
                            showAdd = false
                        }
                        .disabled(addTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
    
    // 越上越重要、越右越緊急（給善甯自己看的提示）
    private var axisHint: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("上：重要")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("右：緊急")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
    
    private func quadrantCell(_ q: TodoQuadrant) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(q.title)
                .font(.headline)
            
            VStack(spacing: 8) {
                let list = store.items(in: q)
                if list.isEmpty {
                    Text("目前沒有待辦")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(list) { item in
                        todoRow(item)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private func todoRow(_ item: TodoItem) -> some View {
        HStack(spacing: 10) {
            Button {
                store.toggleDone(item)
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isDone ? AnyShapeStyle(.secondary) : AnyShapeStyle(theme.accentColor))
            }
            .buttonStyle(.plain)
            
            Text(item.title)
                .font(.body)
                .foregroundStyle(item.isDone ? .secondary : .primary)
                .strikethrough(item.isDone, color: .secondary)
            
            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                store.delete(item)
            } label: {
                Label("刪除", systemImage: "trash")
            }
        }
    }
}
