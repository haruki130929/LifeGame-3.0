//HabitViews
import SwiftUI

struct HabitTrackerView: View {
    @ObservedObject var store: HabitStore
    
    @State private var showAdd = false
    @State private var editing: Habit? = nil
    
    var body: some View {
        List {
            todaySection
            statsSection
        }
        .navigationTitle("習慣追蹤")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                HabitEditorView(mode: .add) { newHabit in
                    store.add(newHabit)
                }
            }
        }
        .sheet(item: $editing) { h in
            NavigationStack {
                HabitEditorView(mode: .edit(h)) { updated in
                    store.update(updated)
                }
            }
        }
    }
    
    private var todaySection: some View {
        Section("今天") {
            let active = store.habits.filter { $0.isActive }
            
            if active.isEmpty {
                Text("目前沒有啟用的習慣")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(active) { h in
                    Button {
                        store.toggle(habit: h, date: Date())
                    } label: {
                        let weekDays = store.weekDates(containing: Date())           // 週一～週日
                        let weekFlags = weekDays.map { store.isDone(h, on: $0) }     // 對應 7 天是否完成
                        let todayIndex = weekDays.firstIndex(where: { Calendar.current.isDateInToday($0) }) ?? -1
                        
                        HabitRow(
                            habit: h,
                            isDoneToday: store.isDoneToday(h),
                            streak: store.streak(for: h),
                            weeklyRate: store.weeklyRate(for: h),
                            weekFlags: weekFlags,
                            todayIndex: todayIndex
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button { editing = h } label: {
                            Label("編輯", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            store.delete(h)
                        } label: {
                            Label("刪除", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    private var statsSection: some View {
        Section("統計") {
            let active = store.habits.filter { $0.isActive }
            let doneToday = active.filter { store.isDoneToday($0) }.count
            let total = active.count
            let overall = store.overallWeeklyRate()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("今日完成：\(doneToday) / \(total)")
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("本週完成率：\(percentText(overall))")
                        .font(.headline)
                    ProgressView(value: overall)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func percentText(_ v: Double) -> String {
        let p = Int((v * 100).rounded())
        return "\(p)%"
    }
}

private struct HabitRow: View {
    let habit: Habit
    let isDoneToday: Bool
    let streak: Int
    let weeklyRate: Double
    let weekFlags: [Bool]    // 7 天：Mon~Sun
    let todayIndex: Int      // 今天在這 7 天中的位置（找不到就 -1）
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: habit.icon)
                .frame(width: 26)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Text("Streak \(streak)")
                        Text("本週 \(percentText(weeklyRate))")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    
                    // ✅ 本週打卡條：Mon~Sun
                    WeekCheckBar(flags: weekFlags, todayIndex: todayIndex)
                }
            }
            
            Spacer()
            
            Image(systemName: isDoneToday ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isDoneToday ? .green : .secondary)
        }
        .contentShape(Rectangle())
    }
    
    private func percentText(_ v: Double) -> String {
        let p = Int((v * 100).rounded())
        return "\(p)%"
    }
}

private struct WeekCheckBar: View {
    let flags: [Bool]       // 期望長度 7
    let todayIndex: Int
    
    private var rate: Double {
        guard !flags.isEmpty else { return 0 }
        let done = flags.filter { $0 }.count
        return Double(done) / Double(flags.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: rate)
                .frame(maxWidth: 180)
            
            HStack(spacing: 4) {
                ForEach(Array(flags.enumerated()), id: \.offset) { i, done in
                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: 14, height: 6)
                        .opacity(done ? 1.0 : 0.25)
                        .overlay {
                            if i == todayIndex {
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(.primary, lineWidth: 1)
                            }
                        }
                }
            }
        }
        .foregroundStyle(.secondary)
    }
}

// MARK: - Editor

enum HabitEditorMode {
    case add
    case edit(Habit)
    
    var title: String {
        switch self {
        case .add: return "新增習慣"
        case .edit: return "編輯習慣"
        }
    }
}

struct HabitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    let mode: HabitEditorMode
    var onDone: (Habit) -> Void
    
    @State private var name: String = ""
    @State private var icon: String = "checkmark.circle"
    @State private var isActive: Bool = true
    
    @FocusState private var nameFocused: Bool
    
    var body: some View {
        Form {
            Section("習慣") {
                TextField("習慣名稱", text: $name)
                    .focused($nameFocused)
            }
            
            Section("Icon") {
                TextField("SF Symbol 名稱", text: $icon)
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title2)
                        .frame(width: 34)
                    Text(icon).foregroundStyle(.secondary)
                }
            }
            
            Section("狀態") {
                Toggle("啟用", isOn: $isActive)
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if case .edit(let h) = mode {
                name = h.name
                icon = h.icon
                isActive = h.isActive
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                nameFocused = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") {
                    let t = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !t.isEmpty else { return }
                    
                    switch mode {
                    case .add:
                        onDone(Habit(name: t, icon: icon, isActive: isActive))
                    case .edit(let old):
                        var updated = old
                        updated.name = t
                        updated.icon = icon
                        updated.isActive = isActive
                        onDone(updated)
                    }
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
