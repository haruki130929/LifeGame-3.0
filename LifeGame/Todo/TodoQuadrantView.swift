import SwiftUI

// MARK: - Large Card（主畫面預覽）
struct TodoQuadrantCardLarge: View {
    @EnvironmentObject private var theme: ThemeStore
    @ObservedObject var store: TodoQuadrantStore

    // ── 點象限 → 新增該象限的待辦 ──
    @State private var addQuadrant: TodoQuadrant? = nil

    // ── 點卡片其他地方 → 進到功能頁 ──
    @State private var showPage = false

    var body: some View {
        cardBody
            .contentShape(Rectangle())
            .onTapGesture { showPage = true }
            // 新增待辦 sheet（點象限觸發）
            .sheet(item: $addQuadrant) { quadrant in
                AddTodoToQuadrantSheet(store: store, quadrant: quadrant)
            }
            // 導航到完整功能頁（點卡片其他區域觸發）
            .navigationDestination(isPresented: $showPage) {
                TodoQuadrantBoardView(store: store)
                    .navigationTitle("待辦四象限")
            }
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("待辦四象限")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

        return Button {
            addQuadrant = q
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(q.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if list.isEmpty {
                    Text("點擊新增")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
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
        .buttonStyle(.plain)
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

// MARK: - 新增待辦到指定象限（Sheet）
private struct AddTodoToQuadrantSheet: View {
    @ObservedObject var store: TodoQuadrantStore
    let quadrant: TodoQuadrant
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @FocusState private var titleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("輸入待辦事項", text: $title)
                        .focused($titleFocused)
                } header: {
                    Label(quadrant.title, systemImage: "plus.circle")
                }
            }
            .navigationTitle("新增待辦")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        store.add(title: title, quadrant: quadrant)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    titleFocused = true
                }
            }
        }
    }
}

// MARK: - 四象限完整頁
struct TodoQuadrantBoardView: View {
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var fab: FabStore
    @ObservedObject var store: TodoQuadrantStore

    @State private var addQuadrant: TodoQuadrant? = nil
    @State private var isEditMode = false

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
        // ── FAB 選單接入 ──
        .onAppear {
            fab.apply(context: .feature(.todoQuadrant))
        }
        .onDisappear {
            fab.popActions()
        }
        .onChange(of: fab.route) { _, newRoute in
            switch newRoute {
            case .addTodoToQuadrant(let q):
                fab.route = nil
                addQuadrant = q
            case .todoEditMode:
                fab.route = nil
                withAnimation { isEditMode.toggle() }
            default:
                break
            }
        }
        .sheet(item: $addQuadrant) { quadrant in
            AddTodoToQuadrantSheet(store: store, quadrant: quadrant)
        }
        .environment(\.editMode, isEditMode ? .constant(.active) : .constant(.inactive))
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
