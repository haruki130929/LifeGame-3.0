import SwiftUI

struct CommunicationBoardView: View {
    @EnvironmentObject private var theme: ThemeStore

    /// 所有已確定的訊息（對話歷史）
    @State private var messages: [String] = []
    /// 正在輸入的文字（即時同步到對方）
    @State private var currentInput: String = ""
    /// 字體大小
    @State private var fontSize: CGFloat = 24
    /// 匯出 sheet
    @State private var showExport = false
    @State private var exportText = ""
    /// 輸入框是否聚焦（＝我正在打字）→ 對面方向顯示提示
    @FocusState private var isInputFocused: Bool

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // ── 上半：對方看的（翻轉 180°）──
                otherSide(height: geo.size.height * 0.45)

                // ── 分隔線 ──
                Rectangle()
                    .fill(theme.accentColor.opacity(0.3))
                    .frame(height: 3)

                // ── 下半：自己操作的 ──
                mySide
            }
        }
        .navigationTitle("溝通板")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 10) {
                    // 縮小字體
                    Button {
                        if fontSize > 14 { fontSize -= 2 }
                    } label: {
                        Image(systemName: "textformat.size.smaller")
                    }
                    .disabled(fontSize <= 14)

                    // 放大字體
                    Button {
                        if fontSize < 48 { fontSize += 2 }
                    } label: {
                        Image(systemName: "textformat.size.larger")
                    }
                    .disabled(fontSize >= 48)

                    // 匯出
                    Button {
                        exportConversation()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(messages.isEmpty && currentInput.isEmpty)

                    // 清除
                    Button {
                        messages = []
                        currentInput = ""
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(messages.isEmpty && currentInput.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showExport) {
            ShareSheet(text: exportText)
        }
    }

    // MARK: - 上半（對方看到的，翻轉 180°）

    private func otherSide(height: CGFloat) -> some View {
        ZStack {
            Color(.systemBackground)

            VStack(spacing: 0) {
                // 「我正在打字」提示：只在我聚焦輸入框時出現，給對面的人看
                if isInputFocused {
                    typingIndicator
                        .transition(.opacity)
                }

                Group {
                    if messages.isEmpty && currentInput.isEmpty {
                        Text("等待輸入...")
                            .font(.title3)
                            .foregroundStyle(.tertiary)
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 12) {
                                    // 歷史訊息
                                    ForEach(Array(messages.enumerated()), id: \.offset) { index, msg in
                                        Text(msg)
                                            .font(.system(size: fontSize, weight: .medium))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .id(index)
                                    }

                                    // 正在輸入的文字（淡色）
                                    if !currentInput.isEmpty {
                                        Text(currentInput)
                                            .font(.system(size: fontSize, weight: .medium))
                                            .foregroundStyle(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .id("typing")
                                    }
                                }
                                .padding(20)
                            }
                            .onChange(of: currentInput) { _, _ in
                                withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                            }
                            .onChange(of: messages.count) { _, _ in
                                withAnimation { proxy.scrollTo(messages.count - 1, anchor: .bottom) }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .rotationEffect(.degrees(180))
            .animation(.easeInOut(duration: 0.2), value: isInputFocused)
        }
        .frame(height: height)
        .contentShape(Rectangle())
        .onTapGesture { isInputFocused = false }   // 點對面區 → 取消輸入狀態
    }

    /// 「我正在打字」提示列（已在 otherSide 的旋轉群組內，會自動朝對面方向）
    private var typingIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "ellipsis.bubble")
            Text("我正在打字…")
                .font(.system(size: max(16, fontSize * 0.7), weight: .semibold))
        }
        .foregroundStyle(theme.accentColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.accentColor.opacity(0.12))
    }

    // MARK: - 下半（自己操作的）

    private var mySide: some View {
        VStack(spacing: 0) {
            // 自己這邊也能看歷史
            if !messages.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(messages.enumerated()), id: \.offset) { index, msg in
                                Text(msg)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id("my-\(index)")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 80)
                    .background(Color(.secondarySystemBackground))
                    .contentShape(Rectangle())
                    .onTapGesture { isInputFocused = false }   // 點歷史區 → 取消輸入狀態
                    .onChange(of: messages.count) { _, _ in
                        withAnimation { proxy.scrollTo("my-\(messages.count - 1)", anchor: .bottom) }
                    }
                }

                Divider()
            }

            // 輸入區（像備忘錄，多行輸入）
            TextEditor(text: $currentInput)
                .font(.body)
                .focused($isInputFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minHeight: 60)
                .scrollContentBackground(.hidden)
                .background(Color(.systemBackground))

            // 確定按鈕
            HStack {
                Spacer()
                Button {
                    confirmMessage()
                } label: {
                    Text("確定顯示")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.secondary.opacity(0.2)
                                : theme.accentColor
                        )
                        .foregroundStyle(
                            currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.secondary
                                : Color.white
                        )
                        .clipShape(Capsule())
                }
                .disabled(currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.trailing, 16)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Actions

    private func confirmMessage() {
        let t = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        messages.append(t)
        currentInput = ""
    }

    private func exportConversation() {
        var lines: [String] = []
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "zh_TW")
        fmt.dateFormat = "yyyy/M/d HH:mm"
        lines.append("溝通紀錄 — \(fmt.string(from: Date()))")
        lines.append("")
        for (i, msg) in messages.enumerated() {
            lines.append("\(i + 1). \(msg)")
        }
        if !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("\(messages.count + 1). \(currentInput)（輸入中）")
        }
        exportText = lines.joined(separator: "\n")
        showExport = true
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
