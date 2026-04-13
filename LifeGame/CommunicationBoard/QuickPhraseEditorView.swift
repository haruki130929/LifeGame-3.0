import SwiftUI

struct QuickPhraseEditorView: View {
    @ObservedObject var store: CommunicationBoardStore
    @Environment(\.dismiss) private var dismiss

    @State private var newPhrase = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("新增常用句子", text: $newPhrase)
                            .focused($isFocused)
                            .submitLabel(.done)
                            .onSubmit { addPhrase() }

                        Button {
                            addPhrase()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.green)
                        }
                        .disabled(newPhrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section("常用句子（拖曳排序）") {
                    ForEach(store.phrases, id: \.self) { phrase in
                        Text(phrase)
                    }
                    .onDelete(perform: store.delete)
                    .onMove(perform: store.move)
                }
            }
            .navigationTitle("編輯常用句子")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.editMode, .constant(.active))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func addPhrase() {
        store.add(newPhrase)
        newPhrase = ""
    }
}
