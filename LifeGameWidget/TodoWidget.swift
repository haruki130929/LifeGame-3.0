//
//  TodoWidget.swift
//  LifeGameWidget
//
//  互動式待辦 Widget：列出未完成待辦，點一下打勾完成。
//
//  寫回機制：複用 app 既有的「Watch → iOS」變更通道 —— 改寫 App Group 的
//  shared.todos 並 bump shared.watchTodosUpdatedAt；app 回前景時
//  WatchChangeObserver 會自動把 isDone 合併回真正的 store（app 端不需任何改動）。
//
//  型別刻意內聯，與 app 端 TodoItem / TodoQuadrant 的 Codable JSON 結構一致，
//  讓 widget 完全獨立編譯。
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - 與 app 端一致的 Codable 型別

enum WTodoQuadrant: Int, Codable {
    case importantNotUrgent = 0
    case importantUrgent = 1
    case notImportantNotUrgent = 2
    case urgentNotImportant = 3

    var title: String {
        switch self {
        case .importantNotUrgent:    return String(localized: "重要不緊急")
        case .importantUrgent:       return String(localized: "重要又緊急")
        case .notImportantNotUrgent: return String(localized: "不重要不緊急")
        case .urgentNotImportant:    return String(localized: "緊急不重要")
        }
    }
    var icon: String {
        switch self {
        case .importantNotUrgent:    return "star.circle"
        case .importantUrgent:       return "exclamationmark.circle"
        case .notImportantNotUrgent: return "minus.circle"
        case .urgentNotImportant:    return "bolt.circle"
        }
    }
}

struct WTodoItem: Identifiable, Codable {
    var id: UUID
    var title: String
    var quadrant: WTodoQuadrant
    var isDone: Bool
    var createdAt: Date
    var startDate: Date?
    var dueDate: Date?
}

// MARK: - App Group 橋接

enum WidgetTodoBridge {
    static let appGroupID = "group.com.haruki.lifegame"
    static let todosKey = "shared.todos"
    static let updatedAtKey = "shared.watchTodosUpdatedAt"
    static let quadrantKey = "widget.todoQuadrant"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    /// App 設定頁選的象限（沒設過 → 預設「重要又緊急」）
    static func selectedQuadrant() -> WTodoQuadrant {
        guard let d = defaults, d.object(forKey: quadrantKey) != nil else { return .importantUrgent }
        return WTodoQuadrant(rawValue: d.integer(forKey: quadrantKey)) ?? .importantUrgent
    }

    static func loadTodos() -> [WTodoItem] {
        guard let d = defaults,
              let data = d.data(forKey: todosKey),
              let items = try? JSONDecoder().decode([WTodoItem].self, from: data)
        else { return [] }
        return items
    }

    /// 把某項待辦標記完成，並通知 app 合併
    static func markDone(idString: String) {
        guard let d = defaults,
              let uuid = UUID(uuidString: idString),
              let data = d.data(forKey: todosKey),
              var items = try? JSONDecoder().decode([WTodoItem].self, from: data),
              let idx = items.firstIndex(where: { $0.id == uuid })
        else { return }

        items[idx].isDone = true
        guard let newData = try? JSONEncoder().encode(items) else { return }
        d.set(newData, forKey: todosKey)
        // bump 時間戳 → app 回前景時 WatchChangeObserver 會合併回 store
        d.set(Date().timeIntervalSince1970, forKey: updatedAtKey)
    }
}

// MARK: - 互動 Intent

struct ToggleTodoDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "完成待辦"

    @Parameter(title: "Todo ID")
    var todoID: String

    init() {}
    init(todoID: String) { self.todoID = todoID }

    func perform() async throws -> some IntentResult {
        WidgetTodoBridge.markDone(idString: todoID)
        return .result()
    }
}

// MARK: - Timeline

struct TodoEntry: TimelineEntry {
    let date: Date
    let quadrant: WTodoQuadrant
    let todos: [WTodoItem]   // 已過濾：只留該象限、未完成
}

struct TodoProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: Date(), quadrant: .importantUrgent, todos: Self.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())
            ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> TodoEntry {
        // 取「App 設定頁選的象限」裡未完成的待辦
        let quadrant = WidgetTodoBridge.selectedQuadrant()
        let items = WidgetTodoBridge.loadTodos()
            .filter { !$0.isDone && $0.quadrant == quadrant }
            .sorted { $0.createdAt > $1.createdAt }
        return TodoEntry(date: Date(), quadrant: quadrant, todos: Array(items.prefix(8)))
    }

    static let sample: [WTodoItem] = [
        WTodoItem(id: UUID(), title: String(localized: "回覆老師的訊息"), quadrant: .importantUrgent, isDone: false, createdAt: Date()),
        WTodoItem(id: UUID(), title: String(localized: "交報告"), quadrant: .importantUrgent, isDone: false, createdAt: Date())
    ]
}

// MARK: - View

struct TodoWidgetEntryView: View {
    var entry: TodoProvider.Entry
    @Environment(\.widgetFamily) private var family

    private var maxRows: Int {
        switch family {
        case .systemLarge:  return 8
        case .systemMedium: return 4
        default:            return 3   // small
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: entry.quadrant.icon)
                Text(entry.quadrant.title).bold()
                Spacer()
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if entry.todos.isEmpty {
                Spacer(minLength: 0)
                HStack {
                    Spacer()
                    Text("全部完成 🎉")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer(minLength: 0)
            } else {
                ForEach(entry.todos.prefix(maxRows)) { todo in
                    Button(intent: ToggleTodoDoneIntent(todoID: todo.id.uuidString)) {
                        HStack(spacing: 8) {
                            Image(systemName: "circle")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text(todo.title)
                                .font(.footnote)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Widget

struct TodoWidget: Widget {
    let kind = "LifeGameTodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoProvider()) { entry in
            TodoWidgetEntryView(entry: entry)
                .widgetAppearance()
        }
        .configurationDisplayName("待辦")
        .description("點一下打勾完成待辦（在 App 設定頁選象限）")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    TodoWidget()
} timeline: {
    TodoEntry(date: .now, quadrant: .importantUrgent, todos: TodoProvider.sample)
}
