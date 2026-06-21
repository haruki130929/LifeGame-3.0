//
//  TodoLiveActivity.swift
//  LifeGameWidget
//
//  「待辦」Live Activity 的 UI：鎖定畫面 + 靈動島，含「完成」互動鈕。
//  按「完成」會在背景把待辦打勾，並自動換成下一筆（邏輯在 CompleteTodoFromLiveActivityIntent）。
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 16.1, *)
struct TodoLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TodoActivityAttributes.self) { context in
            // MARK: 鎖定畫面 / 橫幅
            TodoLockView(state: context.state)
                .padding(14)
                .activityBackgroundTint(Color(white: 0.12))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            // MARK: 靈動島
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "checklist")
                        .foregroundStyle(.orange)
                        .font(.title3)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("剩 \(context.state.remaining)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.title)
                            .font(.callout).bold()
                            .lineLimit(1)
                        if !context.state.dueText.isEmpty {
                            Text(context.state.dueText)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    completeButton(todoID: context.state.todoID)
                        .frame(maxWidth: .infinity)
                }
            } compactLeading: {
                Image(systemName: "checklist")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                Text("\(context.state.remaining)")
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "checklist")
                    .foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private func completeButton(todoID: String) -> some View {
        if #available(iOS 17.0, *) {
            Button(intent: CompleteTodoFromLiveActivityIntent(todoID: todoID)) {
                Label("完成", systemImage: "checkmark.circle.fill")
            }
            .tint(.green)
        }
    }
}

// MARK: - 鎖定畫面內容

@available(iOS 16.1, *)
private struct TodoLockView: View {
    let state: TodoActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "checklist").foregroundStyle(.orange)
                    Text("待辦").font(.caption2).foregroundStyle(.secondary)
                    if state.remaining > 1 {
                        Text("· 剩 \(state.remaining)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Text(state.title)
                    .font(.headline)
                    .lineLimit(1)
                if !state.dueText.isEmpty {
                    Text(state.dueText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            if #available(iOS 17.0, *) {
                Button(intent: CompleteTodoFromLiveActivityIntent(todoID: state.todoID)) {
                    Label("完成", systemImage: "checkmark.circle.fill")
                }
                .tint(.green)
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
