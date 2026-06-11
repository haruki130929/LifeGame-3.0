import SwiftUI

/// 練習日記列表 — 顯示所有使用者建立的練習日記
struct PracticeDiaryListView: View {
    @StateObject private var store = PracticeDiaryStore()
    @EnvironmentObject private var fab: FabStore
    @State private var showingAddDiary = false
    @State private var diaryToEdit: PracticeDiary?
    @State private var isEditMode = false

    var body: some View {
        Group {
            if store.diaries.isEmpty {
                ContentUnavailableView(
                    "還沒有練習日記",
                    systemImage: "pencil.and.list.clipboard",
                    description: Text("建立你的第一本練習日記，開始追蹤練習進度")
                )
            } else {
                List {
                    ForEach(store.diaries) { diary in
                        NavigationLink {
                            PracticeEntryListView(diary: diary, store: store)
                                .hidesFab()
                        } label: {
                            diaryRow(diary)
                        }
                        .contextMenu {
                            Button {
                                diaryToEdit = diary
                            } label: {
                                Label("編輯", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                store.deleteDiary(id: diary.id)
                            } label: {
                                Label("刪除", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            store.deleteDiary(id: store.diaries[index].id)
                        }
                    }
                }
                .environment(\.editMode, isEditMode ? .constant(.active) : .constant(.inactive))
            }
        }
        .navigationTitle("練習日記")
        .onAppear { fab.apply(context: .feature(.practiceDiary)) }
        .onDisappear { fab.popActions() }
        .onChange(of: fab.route) { _, newRoute in
            switch newRoute {
            case .addPracticeDiary:
                fab.route = nil
                showingAddDiary = true
            case .practiceDiaryEditMode:
                fab.route = nil
                isEditMode.toggle()
            default:
                break
            }
        }
        .sheet(isPresented: $showingAddDiary) {
            NavigationStack {
                PracticeDiaryConfigView(mode: .create) { diary in
                    store.addDiary(diary)
                }
            }
        }
        .sheet(item: $diaryToEdit) { diary in
            NavigationStack {
                PracticeDiaryConfigView(mode: .edit(diary)) { updated in
                    store.updateDiary(updated)
                }
            }
        }
    }

    // MARK: - Row

    private func diaryRow(_ diary: PracticeDiary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: diary.icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(diary.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text("\(diary.fields.count) 個欄位")
                    Text("·")
                    Text("\(store.entryCount(for: diary.id)) 筆紀錄")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
