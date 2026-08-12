import SwiftUI

/// 「檢視紀錄字體大小」調整面板：由每日紀錄的「＋」選單開啟。
///
/// 用滑桿選級距，上方即時預覽套用後的效果。設定寫入 `DailyLogTextSize.storageKey`，
/// 主列表與檢視 sheet 會即時跟著變。
struct DailyLogFontSizeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(DailyLogTextSize.storageKey) private var index: Int = DailyLogTextSize.defaultIndex

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                // 即時預覽：長得像一列每日紀錄，套用目前選到的字體大小。
                previewCard
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                // 滑桿：小 A ←→ 大 A
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        Text("A")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Slider(
                            value: Binding(
                                get: { Double(DailyLogTextSize.clampedIndex(index)) },
                                set: { index = Int($0.rounded()) }
                            ),
                            in: 0...Double(DailyLogTextSize.options.count - 1),
                            step: 1
                        )
                        Text("A")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                    Text("目前：\(DailyLogTextSize.label(forIndex: index))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button("恢復預設") { index = DailyLogTextSize.defaultIndex }
                    .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
            .navigationTitle("檢視紀錄字體大小")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    /// 預覽卡片：對齊 `DailyLogRow` 的排版與字體，讓調整結果所見即所得。
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("2026年7月7日")
                    .font(DailyLogTextSize.font(17, weight: .semibold, forIndex: index))
                Spacer()
                Text("晴")
                    .font(DailyLogTextSize.font(17, forIndex: index))
                    .foregroundStyle(.secondary)
            }
            Text("情緒 8｜焦慮 3｜疲勞 4")
                .font(DailyLogTextSize.font(15, forIndex: index))
                .foregroundStyle(.secondary)
            Text("今天狀態不錯，午後有點分心。")
                .font(DailyLogTextSize.font(12, forIndex: index))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}
