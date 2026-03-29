import SwiftUI

struct QuestionModuleSettingsView: View {
    @EnvironmentObject private var moduleStore: QuestionModuleStore
    @State private var showingAddSheet = false
    @State private var showDeleteConfirm = false
    @State private var moduleToDelete: DailyLogModule?
    @State private var isEditMode = false
    @State private var showActionMenu = false

    private var sortedModules: [DailyLogModule] {
        moduleStore.modules.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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

            // 右下角 ＋ 按鈕
            Menu {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("新增模組", systemImage: "plus.circle")
                }
                Button {
                    isEditMode.toggle()
                } label: {
                    Label(isEditMode ? "完成排序" : "排序", systemImage: isEditMode ? "checkmark" : "arrow.up.arrow.down")
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Color.accentColor))
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .navigationTitle("問題模組管理")
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

    // MARK: - 模組列（所有模組都可編輯、可刪除）

    private func moduleRow(_ module: DailyLogModule) -> some View {
        NavigationLink {
            CustomModuleEditorView(mode: .edit(module)) { updated in
                if module.kind.isBuiltIn {
                    // 內建模組：更新 title/icon/questions
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
                Text(module.displayTitle)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { module.isEnabled },
                    set: { _ in moduleStore.toggle(id: module.id) }
                ))
                .labelsHidden()
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

    // MARK: - 排序

    private func moveModules(from source: IndexSet, to destination: Int) {
        moduleStore.reorder(from: source, to: destination)
    }
}
