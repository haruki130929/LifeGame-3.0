import SwiftUI

struct QuestionModuleSettingsView: View {
    @EnvironmentObject private var moduleStore: QuestionModuleStore
    @EnvironmentObject private var fab: FabStore
    @State private var showingAddSheet = false
    @State private var showDeleteConfirm = false
    @State private var moduleToDelete: DailyLogModule?
    @State private var isEditMode = false

    private var sortedModules: [DailyLogModule] {
        moduleStore.modules.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            Section {
                ForEach(sortedModules) { module in
                    moduleRow(module)
                }
                .onMove(perform: moveModules)
            } header: {
                Text("點選模組可編輯，左滑可刪除")
            }
        }
        .environment(\.editMode, isEditMode ? .constant(.active) : .constant(.inactive))
        .navigationTitle("問題模組管理")
        .onAppear { fab.apply(context: .feature(.questionModule)) }
        .onDisappear { fab.popActions() }
        .onChange(of: fab.route) { _, newRoute in
            switch newRoute {
            case .addQuestionModule:
                fab.route = nil
                showingAddSheet = true
            case .questionModuleEditMode:
                fab.route = nil
                isEditMode.toggle()
            default:
                break
            }
        }
        .confirmationDialog("確定要刪除「\(moduleToDelete?.displayTitle ?? "")」嗎？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("刪除", role: .destructive) {
                if let m = moduleToDelete {
                    moduleStore.removeModule(id: m.id)
                }
                moduleToDelete = nil
            }
            Button("取消", role: .cancel) { moduleToDelete = nil }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                CustomModuleEditorView(mode: .create) { newModule in
                    moduleStore.addCustomModule(newModule)
                }
            }
        }
    }

    // MARK: - 模組列

    private func moduleRow(_ module: DailyLogModule) -> some View {
        HStack(spacing: 12) {
            // 開關
            Toggle("", isOn: Binding(
                get: { module.isEnabled },
                set: { _ in moduleStore.toggle(id: module.id) }
            ))
            .labelsHidden()
            .fixedSize()

            // 模組資訊（點擊進入編輯）
            NavigationLink {
                CustomModuleEditorView(mode: .edit(module)) { updated in
                    if module.kind.isBuiltIn {
                        moduleStore.updateBuiltInModule(updated)
                    } else {
                        moduleStore.updateCustomModule(updated)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: module.displayIcon)
                        .foregroundStyle(module.kind.isBuiltIn ? .blue : .orange)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(module.displayTitle)
                        let qCount = module.questions?.count ?? 0
                        if qCount > 0 {
                            Text("\(qCount) 個問題")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if module.kind.isBuiltIn {
                            Text("內建模組")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                moduleToDelete = module
                showDeleteConfirm = true
            } label: {
                Label("刪除", systemImage: "trash")
            }
        }
    }

    private func moveModules(from source: IndexSet, to destination: Int) {
        moduleStore.reorder(from: source, to: destination)
    }
}
