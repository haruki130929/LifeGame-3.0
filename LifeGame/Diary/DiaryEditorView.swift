import SwiftUI

struct DiaryEditorView: View {
    enum Mode {
        case add
        case edit(DiaryEntry)
    }

    let mode: Mode
    @ObservedObject var store: DiaryStore
    @EnvironmentObject private var moduleStore: QuestionModuleStore
    @Environment(\.dismiss) private var dismiss

    @State private var entry = DiaryEntry()

    private var title: String {
        switch mode {
        case .add:  return "新增日記"
        case .edit: return "編輯日記"
        }
    }

    var body: some View {
        Form {
            // 1. 日期
            Section("1. 日期") {
                DatePicker("日期", selection: $entry.date, displayedComponents: .date)
            }

            // 2. 日記內容
            Section("2. 日記內容") {
                TextEditor(text: $entry.content)
                    .frame(minHeight: 200)
            }

            // 動態渲染啟用的自訂模組
            ForEach(Array(moduleStore.enabledCustomModules.enumerated()), id: \.element.id) { index, module in
                let header = "\(index + 3). \(module.displayTitle)"
                CustomModuleSectionView(module: module, answers: $entry.answers, header: header)
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                    dismiss()
                }
            }
        }
        .onAppear {
            switch mode {
            case .add:
                entry = DiaryEntry()
            case .edit(let existing):
                entry = existing
            }
        }
    }

    private func save() {
        switch mode {
        case .add:
            store.add(entry)
        case .edit:
            store.update(entry)
        }
    }
}
