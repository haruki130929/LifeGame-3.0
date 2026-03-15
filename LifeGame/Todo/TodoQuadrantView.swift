import SwiftUI

// MARK: - Large Card（主畫面預覽）
struct TodoQuadrantCardLarge: View {
    @EnvironmentObject private var theme: ThemeStore
    @ObservedObject var store: TodoQuadrantStore

    // ── 點象限 → 用 sheet 打開該象限編輯 ──
    @State private var selectedQuadrant: TodoQuadrant? = nil

    var body: some View {
        cardBody
            .sheet(item: $selectedQuadrant) { quadrant in
                NavigationStack {
                    TodoQuadrantBoardView(store: store, focusedQuadrant: quadrant)
                        .navigationTitle(quadrant.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("完成") { selectedQuadrant = nil }
                            }
                        }
                }
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
            selectedQuadrant = q
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(q.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if list.isEmpty {
                    Text("尚無待辦")
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
            Button {
                store.toggleDone(item)
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isDone ? AnyShapeStyle(.secondary) : AnyShapeStyle(theme.accentColor))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isDone ? "標為未完成" : "標為完成")

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

    /// 從卡片點進來時，自動展開的象限
    var focusedQuadrant: TodoQuadrant? = nil

    @State private var addQuadrant: TodoQuadrant? = nil
    @State private var isEditMode = false
    @State private var expandedQuadrant: TodoQuadrant? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {

                // 展開模式的返回按鈕
                if expandedQuadrant != nil {
                    HStack {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                expandedQuadrant = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("全部象限")
                            }
                            .font(.subheadline)
                        }
                        Spacer()
                    }
                } else {
                    axisHint
                }

                // 展開模式：只顯示被選中的象限
                if let expanded = expandedQuadrant {
                    quadrantCell(expanded)
                        .transition(.opacity)
                } else {
                    // 2x2 Grid（點擊可展開單一象限）
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            quadrantCell(.importantNotUrgent)
                                .onTapGesture { withAnimation(.easeInOut(duration: 0.25)) { expandedQuadrant = .importantNotUrgent } }
                            quadrantCell(.importantUrgent)
                                .onTapGesture { withAnimation(.easeInOut(duration: 0.25)) { expandedQuadrant = .importantUrgent } }
                        }
                        HStack(spacing: 12) {
                            quadrantCell(.notImportantNotUrgent)
                                .onTapGesture { withAnimation(.easeInOut(duration: 0.25)) { expandedQuadrant = .notImportantNotUrgent } }
                            quadrantCell(.urgentNotImportant)
                                .onTapGesture { withAnimation(.easeInOut(duration: 0.25)) { expandedQuadrant = .urgentNotImportant } }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .padding(14)
        }
        .onAppear {
            fab.apply(context: .feature(.todoQuadrant))
            if let focusedQuadrant {
                expandedQuadrant = focusedQuadrant
            }
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
            HStack {
                Text(q.title)
                    .font(.headline)
                Spacer()
                Button {
                    addQuadrant = q
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(theme.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("新增待辦")
            }

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
        .frame(maxWidth: .infinity, minHeight: expandedQuadrant != nil ? 300 : 220, alignment: .topLeading)
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
            .accessibilityLabel(item.isDone ? "標為未完成" : "標為完成")

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
