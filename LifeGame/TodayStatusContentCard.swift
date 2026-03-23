import SwiftUI
import Combine

struct TodayStatusContentCard: View {
    @ObservedObject var game: LifeGame
    @EnvironmentObject private var slotNameStore: TimeSlotNameStore

    /// 依角色顯示不同按鈕文字
    private var actionButtonTitle: String {
        slotNameStore.role == .worker ? "工作一小時" : "上一堂課"
    }

    /// 上一堂課：記錄按下的時間，1 小時內可取消
    @State private var classUndoTime: Date? = nil
    /// 今日結算：是否可取消
    @State private var canUndoSettle = false

    /// 是否在取消窗口內（1 小時）
    private var canUndoClass: Bool {
        guard let time = classUndoTime else { return false }
        return Date().timeIntervalSince(time) < 3600
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日狀態")
                .font(.headline)

            statRow(title: "HP", current: game.hp.current, max: game.hp.max)
            statRow(title: "FP", current: game.fp.current, max: game.fp.max)
            statRow(title: "MP", current: game.mp.current, max: game.mp.max)

            Divider().opacity(0.35)

            HStack(spacing: 10) {
                if canUndoClass {
                    Button {
                        game.undoClassCost()
                        classUndoTime = nil
                    } label: {
                        Text("取消扣點")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    Button {
                        game.applyClassCost()
                        classUndoTime = Date()
                    } label: {
                        Text(actionButtonTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                if canUndoSettle {
                    Button {
                        game.undoSettle()
                        canUndoSettle = false
                    } label: {
                        Text("取消結算")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    Button {
                        game.settleToday()
                        canUndoSettle = true
                    } label: {
                        Text("今日結算")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }

            HStack(spacing: 10) {
                Button {
                    game.mp.add(5)
                } label: {
                    Text("MP＋5")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    game.mp.add(-5)
                } label: {
                    Text("MP－5")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        // 每分鐘檢查一次，超過 1 小時就自動重置按鈕
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            if classUndoTime != nil && !canUndoClass {
                classUndoTime = nil
            }
        }
    }
    
    @ViewBuilder
    private func statRow(title: String, current: Int, max: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text("\(current) / \(max)")
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(current), total: Double(max))
        }
    }
}
