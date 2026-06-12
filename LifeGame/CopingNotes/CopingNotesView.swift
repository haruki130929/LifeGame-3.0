import SwiftUI

/// 動力筆記：選擇「現在是什麼狀況」→ 跳出對應的應對方法。
/// 內容來自使用者整理的讀書筆記（狀況 → 方法）。
struct CopingNotesView: View {
    @State private var query = ""

    private var situational: [CopingNote] {
        CopingNotesData.all.filter { !$0.situations.isEmpty && matches($0) }
    }
    private var concepts: [CopingNote] {
        CopingNotesData.all.filter { $0.situations.isEmpty && matches($0) }
    }

    private func matches(_ note: CopingNote) -> Bool {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return true }
        return note.method.localizedCaseInsensitiveContains(q)
            || note.situations.contains { $0.localizedCaseInsensitiveContains(q) }
            || note.suggestions.contains { $0.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        List {
            Section {
                Text("選擇你現在的狀況，看看可以試試什麼方法。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if !situational.isEmpty {
                Section("依狀況") {
                    ForEach(situational) { note in
                        NavigationLink {
                            CopingNoteDetailView(note: note)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.situations.joined(separator: "、"))
                                    .font(.body.weight(.medium))
                                Text(note.method)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }

            if !concepts.isEmpty {
                Section("通用技巧 / 觀念") {
                    ForEach(concepts) { note in
                        NavigationLink {
                            CopingNoteDetailView(note: note)
                        } label: {
                            Text(note.method)
                                .font(.body)
                                .lineLimit(2)
                        }
                    }
                }
            }

            if situational.isEmpty && concepts.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .navigationTitle("動力筆記")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "搜尋狀況、方法或關鍵字")
        .hidesFab()   // 純瀏覽頁，隱藏主頁的「＋」FAB
    }
}

// MARK: - 詳細頁（方法 + 具體做法）

struct CopingNoteDetailView: View {
    let note: CopingNote

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !note.situations.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("適用狀況")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        chips(note.situations)
                    }
                }

                Text(note.method)
                    .font(.title3.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)

                if !note.suggestions.isEmpty {
                    Divider()
                    Text("可以試試這些方法")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(note.suggestions.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(.tint)
                                    .font(.body)
                                Text(item)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                Spacer(minLength: 24)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("應對方法")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// 狀況標籤（自動換行的膠囊）
    private func chips(_ items: [String]) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { s in
                Text(s)
                    .font(.footnote)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.tint.opacity(0.12), in: Capsule())
            }
        }
    }
}

// MARK: - 簡易自動換行排列（給狀況標籤用）

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                totalWidth = max(totalWidth, rowWidth - spacing)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth - spacing)
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
