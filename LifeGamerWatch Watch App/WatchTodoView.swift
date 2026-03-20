import SwiftUI

struct WatchTodoView: View {
    @EnvironmentObject var dataStore: WatchDataStore

    private var pendingItems: [TodoItem] {
        dataStore.todoItems.filter { !$0.isDone }
    }

    var body: some View {
        Group {
            if pendingItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                    Text("全部完成！")
                        .font(.headline)
                    Text("沒有待辦事項")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                List {
                    Section {
                        ForEach(pendingItems) { item in
                            TodoRow(item: item) {
                                dataStore.toggleTodo(item)
                            }
                        }
                    } header: {
                        Text("待辦 (\(pendingItems.count))")
                    }
                }
            }
        }
    }
}

// MARK: - 單筆待辦列

private struct TodoRow: View {
    let item: TodoItem
    let onToggle: () -> Void

    private var quadrantColor: Color {
        switch item.quadrant {
        case .importantUrgent:       return .red
        case .importantNotUrgent:    return .orange
        case .urgentNotImportant:    return .yellow
        case .notImportantNotUrgent: return .gray
        }
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Circle()
                    .fill(quadrantColor)
                    .frame(width: 8, height: 8)

                Text(item.title)
                    .font(.body)
                    .lineLimit(2)

                Spacer()

                Image(systemName: "circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
