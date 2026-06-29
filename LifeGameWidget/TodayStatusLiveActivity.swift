//
//  TodayStatusLiveActivity.swift
//  LifeGameWidget
//
//  「今日狀態」Live Activity 的 UI：鎖定畫面橫幅 + 動態島。
//  資料來自 App 端透過 ActivityKit 推送的 TodayStatusAttributes.ContentState。
//

// Live Activity UI：Mac Catalyst 不支援 ActivityKit，整檔在 Catalyst 上排除編譯。
#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct TodayStatusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TodayStatusAttributes.self) { context in
            // MARK: 鎖定畫面 / 橫幅
            LockScreenView(state: context.state)
                .padding(14)
                .activityBackgroundTint(Color(white: 0.12))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            // MARK: 動態島
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    statColumn("HP", context.state.hp, context.state.hpMax, color: .red)
                }
                DynamicIslandExpandedRegion(.center) {
                    statColumn("FP", context.state.fp, context.state.fpMax, color: .orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    statColumn("MP", context.state.mp, context.state.mpMax, color: .blue)
                }
            } compactLeading: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
            } compactTrailing: {
                Text("\(context.state.hp)")
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private func statColumn(_ label: String, _ value: Int, _ maxValue: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(color)
        }
    }
}

// MARK: - 鎖定畫面 / 橫幅內容

@available(iOS 16.1, *)
private struct LockScreenView: View {
    let state: TodayStatusAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日狀態")
                .font(.caption).bold()
                .foregroundStyle(.secondary)

            statRow(icon: "heart.fill", color: .red, label: "HP", value: state.hp, max: state.hpMax)
            statRow(icon: "flame.fill", color: .orange, label: "FP", value: state.fp, max: state.fpMax)
            statRow(icon: "brain.head.profile", color: .blue, label: "MP", value: state.mp, max: state.mpMax)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statRow(icon: String, color: Color, label: String, value: Int, max: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
                .frame(width: 18)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            // 進度條
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * fraction(value, max))
                }
            }
            .frame(height: 6)

            Text("\(value)")
                .font(.caption).bold()
                .monospacedDigit()
                .frame(width: 34, alignment: .trailing)
        }
    }

    private func fraction(_ value: Int, _ max: Int) -> Double {
        guard max > 0 else { return 0 }
        return Swift.min(1, Swift.max(0, Double(value) / Double(max)))
    }
}
#endif
