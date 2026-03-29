import SwiftUI

struct QuestionModuleSettingsView: View {
    @EnvironmentObject private var moduleStore: QuestionModuleStore
    @State private var showingAddSheet = false
    @State private var showDeleteConfirm = false
    @State private var moduleToDelete: DailyLogModule?

    /// 依 sortOrder 排序的模組清單（用於 List 顯示）
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
                Text("拖曳排序，開關控制是否顯示")
            } footer: {
                Text("內建模組無法刪除，僅可開關與排序")
            }
        }
        .navigationTitle("問題模組管理")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                EditButton().environment(\.locale, Locale(identifier: "zh-Hant"))
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

    @ViewBuilder
    private func moduleRow(_ module: DailyLogModule) -> some View {
        if module.kind.isBuiltIn {
            HStack {
                Image(systemName: module.displayIcon)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                Text(module.displayTitle)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { module.isEnabled },
                    set: { _ in moduleStore.toggle(id: module.id) }
                ))
                .labelsHidden()
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    moduleToDelete = module
                    showDeleteConfirm = true
                } label: {
                    Label("刪除", systemImage: "trash")
                }
            }
        } else {
            NavigationLink {
                CustomModuleEditorView(mode: .edit(module)) { updated in
                    moduleStore.updateCustomModule(updated)
                }
            } label: {
                HStack {
                    Image(systemName: module.displayIcon)
                        .foregroundStyle(.orange)
                        .frame(width: 24)
                    Text(module.displayTitle)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { module.isEnabled },
                        set: { _ in moduleStore.toggle(id: module.id) }
                    ))
                    .labelsHidden()
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    moduleToDelete = module
                    showDeleteConfirm = true
                } label: {
                    Label("刪除", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - 排序

    private func moveModules(from source: IndexSet, to destination: Int) {
        moduleStore.reorder(from: source, to: destination)
    }
}
