//
//  LifeGameWidget.swift
//  LifeGameWidget
//
//  今日狀態 Widget：讀取 app 寫進 App Group 共享區的 HP/FP/MP 快照。
//  刻意「內聯」所有型別與常數 → widget 完全不依賴 app 端檔案，保證能獨立編譯。
//

import WidgetKit
import SwiftUI

// MARK: - 共享快照（JSON 結構需與 app 端 WatchSyncHelper.SyncStatsPayload 一致）

private enum WidgetShared {
    static let appGroupID = "group.com.haruki.lifegame"
    static let statsKey = "shared.stats"

    struct Stat: Codable { var current: Int; var max: Int }
    struct StatsPayload: Codable { var hp: Stat; var fp: Stat; var mp: Stat }

    static func loadStats() -> StatsPayload? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: statsKey) else { return nil }
        return try? JSONDecoder().decode(StatsPayload.self, from: data)
    }
}

// MARK: - Timeline

struct StatsEntry: TimelineEntry {
    let date: Date
    let hp: Int
    let fp: Int
    let mp: Int
    var isPlaceholder = false
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> StatsEntry {
        StatsEntry(date: Date(), hp: 80, fp: 60, mp: 90, isPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsEntry>) -> Void) {
        // app 端在資料變動時會主動呼叫 WidgetCenter.reloadAllTimelines()；
        // 這裡再保險每 30 分鐘自動刷新一次。
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())
            ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> StatsEntry {
        if let s = WidgetShared.loadStats() {
            return StatsEntry(date: Date(), hp: s.hp.current, fp: s.fp.current, mp: s.mp.current)
        }
        return StatsEntry(date: Date(), hp: 0, fp: 0, mp: 0)
    }
}

// MARK: - View

struct LifeGameWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日狀態")
                .font(.caption).bold()
                .foregroundStyle(.secondary)

            statRow(icon: "heart.fill", color: .red, label: "HP", value: entry.hp)
            statRow(icon: "flame.fill", color: .orange, label: "FP", value: entry.fp)
            statRow(icon: "brain.head.profile", color: .blue, label: "MP", value: entry.mp)
        }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func statRow(icon: String, color: Color, label: String, value: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
                .frame(width: 18)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            Text("\(value)")
                .font(.callout).bold()
                .monospacedDigit()
        }
    }
}

// MARK: - Widget

struct LifeGameWidget: Widget {
    let kind = "LifeGameWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LifeGameWidgetEntryView(entry: entry)
                .widgetAppearance()
        }
        .configurationDisplayName("今日狀態")
        .description("顯示今天的 HP / FP / MP")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    LifeGameWidget()
} timeline: {
    StatsEntry(date: .now, hp: 80, fp: 60, mp: 90)
}
