import SwiftUI

struct CommunicationBoardView: View {
    @StateObject private var store = CommunicationBoardStore()
    @EnvironmentObject private var theme: ThemeStore

    @State private var currentText: String = ""
    @State private var inputText: String = ""
    @State private var showPhraseEditor = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // ── 上半：對方看的（翻轉 180°）──
                otherSide(height: geo.size.height * 0.4)

                // ── 分隔線 ──
                dividerBar

                // ── 下半：自己操作的 ──
                mySide
            }
        }
        .navigationTitle("溝通板")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showPhraseEditor = true
                } label: {
                    Image(systemName: "list.bullet.rectangle.portrait")
                }
            }
        }
        .sheet(isPresented: $showPhraseEditor) {
            QuickPhraseEditorView(store: store)
        }
    }

    // MARK: - 上半（對方看到的，翻轉 180°）

    private func otherSide(height: CGFloat) -> some View {
        ZStack {
            Color(.systemBackground)

            if currentText.isEmpty {
                Text("等待輸入...")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(180))
            } else {
                ScrollView {
                    Text(currentText)
                        .font(.system(size: 32, weight: .medium))
                        .multilineTextAlignment(.center)
                        .padding(24)
                        .frame(maxWidth: .infinity)
                }
                .rotationEffect(.degrees(180))
            }
        }
        .frame(height: height)
    }

    // MARK: - 分隔線

    private var dividerBar: some View {
        Rectangle()
            .fill(theme.accentColor.opacity(0.3))
            .frame(height: 3)
    }

    // MARK: - 下半（自己操作的）

    private var mySide: some View {
        VStack(spacing: 12) {
            // 目前文字預覽
            if !currentText.isEmpty {
                HStack {
                    Text(currentText)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Spacer()

                    Button {
                        withAnimation { currentText = "" }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            // 常用句子按鈕
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(store.phrases, id: \.self) { phrase in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                currentText = phrase
                            }
                        } label: {
                            Text(phrase)
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    currentText == phrase
                                        ? theme.accentColor.opacity(0.2)
                                        : Color(.tertiarySystemFill)
                                )
                                .foregroundStyle(
                                    currentText == phrase
                                        ? theme.accentColor
                                        : .primary
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            Spacer(minLength: 0)

            // 輸入框
            HStack(spacing: 10) {
                TextField("輸入想說的話...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit { sendInput() }

                Button {
                    sendInput()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : theme.accentColor)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    private func sendInput() {
        let t = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            currentText = t
        }
        inputText = ""
    }
}
