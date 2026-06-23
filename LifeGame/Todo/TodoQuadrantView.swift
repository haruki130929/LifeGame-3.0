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
        VStack(alignment: .leading, spacing: 14) {
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
    @State private var hasStartDate = false
    @State private var startDate = Date()
    @State private var hasDueDate = false
    @State private var dueDate = Date()
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

                Section {
                    Toggle("設定開始日期", isOn: $hasStartDate)
                    if hasStartDate {
                        DatePicker("開始時間", selection: $startDate)
                    }
                    Toggle("設定截止日期", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("截止日期", selection: $dueDate, in: Date()..., displayedComponents: .date)
                        DatePicker("截止時間", selection: $dueDate, in: Date()..., displayedComponents: .hourAndMinute)
                    }
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
                        store.add(
                            title: title,
                            quadrant: quadrant,
                            startDate: hasStartDate ? startDate : nil,
                            dueDate: hasDueDate ? dueDate : nil
                        )
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
        .featureTutorial(.todoQuadrant)
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

    @State private var startDateEditItem: TodoItem? = nil
    @State private var editingStartDate = Date()
    @State private var dueDateEditItem: TodoItem? = nil
    @State private var editingDueDate = Date()
    @State private var editingHasDue = false

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

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body)
                    .foregroundStyle(item.isDone ? .secondary : .primary)
                    .strikethrough(item.isDone, color: .secondary)

                if let days = item.daysUntilDue, let dueDate = item.dueDate, !item.isDone {
                    dueDateLabel(days: days, dueDate: dueDate)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                editingStartDate = item.startDate ?? Date()
                startDateEditItem = item
            } label: {
                Label(item.startDate == nil ? "設定開始日期" : "修改開始日期", systemImage: "calendar.badge.plus")
            }
            if item.startDate != nil {
                Button {
                    store.updateStartDate(nil, for: item)
                } label: {
                    Label("移除開始日期", systemImage: "calendar.badge.minus")
                }
            }
            Button {
                editingHasDue = item.dueDate != nil
                editingDueDate = item.dueDate ?? Date()
                dueDateEditItem = item
            } label: {
                Label(item.dueDate == nil ? "設定截止日期" : "修改截止日期", systemImage: "calendar.badge.clock")
            }
            if item.dueDate != nil {
                Button {
                    store.updateDueDate(nil, for: item)
                } label: {
                    Label("移除截止日期", systemImage: "calendar.badge.minus")
                }
            }
            Button(role: .destructive) {
                store.delete(item)
            } label: {
                Label("刪除", systemImage: "trash")
            }
        }
        .sheet(item: $startDateEditItem) { item in
            NavigationStack {
                Form {
                    DatePicker("開始時間", selection: $editingStartDate)
                }
                .navigationTitle("設定開始日期")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { startDateEditItem = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("儲存") {
                            store.updateStartDate(editingStartDate, for: item)
                            startDateEditItem = nil
                        }
                    }
                }
            }
        }
        .sheet(item: $dueDateEditItem) { item in
            NavigationStack {
                Form {
                    DatePicker("截止日期", selection: $editingDueDate, in: Date()..., displayedComponents: .date)
                    DatePicker("截止時間", selection: $editingDueDate, in: Date()..., displayedComponents: .hourAndMinute)
                }
                .navigationTitle("設定截止日期")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { dueDateEditItem = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("儲存") {
                            store.updateDueDate(editingDueDate, for: item)
                            dueDateEditItem = nil
                        }
                    }
                }
            }
        }
    }

    private func dueDateLabel(days: Int, dueDate: Date) -> some View {
        let (text, color): (String, Color) = {
            if days < 0 {
                return ("已過期", .red)
            } else if days == 0 {
                return ("今天 \(dueDate.formatted(date: .omitted, time: .shortened)) 到期", .red)
            } else if days == 1 {
                return ("明天到期", .orange)
            } else if days <= 7 {
                return ("剩 \(days) 天", .orange)
            } else {
                return ("剩 \(days) 天", .secondary)
            }
        }()
        return Text(text)
            .font(.caption)
            .foregroundStyle(color)
    }
}
