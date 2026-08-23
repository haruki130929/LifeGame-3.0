import SwiftUI

// MARK: - ClassScheduleEditorV2

struct ClassScheduleEditorV2: View {
    @EnvironmentObject private var store: TomorrowRingStore
    @EnvironmentObject private var theme: ThemeStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDay: Weekday = .today
    @State private var editingCourse: ClassScheduleV2.CourseSlot?
    @State private var showAddCourse = false

    var body: some View {
        VStack(spacing: 0) {
            // Day selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Weekday.allCases) { day in
                        Button {
                            selectedDay = day
                        } label: {
                            Text(day.shortTitle)
                                .font(.subheadline.weight(day == selectedDay ? .bold : .regular))
                                .foregroundStyle(day == selectedDay ? theme.accentColor : .secondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(day == selectedDay ? theme.accentColor.opacity(0.12) : Color.clear)
                                )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Divider()

            // Course list
            let courses = store.classSchedule.courses(for: selectedDay)

            if courses.isEmpty {
                ContentUnavailableView {
                    Label("沒有課程", systemImage: "book.closed")
                } description: {
                    Text("點擊右上角 + 新增課程")
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(courses) { course in
                        courseRow(course)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.classSchedule.removeCourse(id: course.id, for: selectedDay)
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("課表")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddCourse = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("完成") { dismiss() }
            }
        }
        .sheet(isPresented: $showAddCourse) {
            CourseEditSheet(day: selectedDay)
                .environmentObject(store)
                .environmentObject(theme)
        }
        .sheet(item: $editingCourse) { course in
            CourseEditSheet(day: selectedDay, editing: course)
                .environmentObject(store)
                .environmentObject(theme)
        }
    }

    @ViewBuilder
    private func courseRow(_ course: ClassScheduleV2.CourseSlot) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: course.colorHex))
                .frame(width: 10, height: 10)

            Image(systemName: course.icon)
                .font(.caption)
                .frame(width: 20)

            Text(course.title)
                .font(.subheadline)

            Spacer()

            Text("\(RingTimeHelpers.timeString(for: course.startMinute))–\(RingTimeHelpers.timeString(for: course.endMinute))")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editingCourse = course
        }
    }
}

// MARK: - CourseEditSheet

private struct CourseEditSheet: View {
    @EnvironmentObject private var store: TomorrowRingStore
    @Environment(\.dismiss) private var dismiss

    let day: Weekday
    var editing: ClassScheduleV2.CourseSlot?

    @State private var title = ""
    @State private var icon = "book"
    @State private var colorHex = "5B9BD5"
    @State private var startDate = RingTimeHelpers.date(from: 540)
    @State private var endDate = RingTimeHelpers.date(from: 630)
    @State private var hpCost = 10
    @State private var fpCost = 10

    var body: some View {
        NavigationStack {
            Form {
                TextField("課程名稱", text: $title)

                CompactPaletteColorPicker(selectedHex: $colorHex)

                Section("時間") {
                    RingTimeField(title: "開始", date: $startDate)
                    RingTimeField(title: "結束", date: $endDate)
                }

                Section("資源消耗") {
                    Stepper("HP：\(hpCost)", value: $hpCost, in: 0...50, step: 5)
                    Stepper("FP：\(fpCost)", value: $fpCost, in: 0...50, step: 5)
                }

                if editing != nil {
                    Section {
                        Button(role: .destructive) {
                            if let id = editing?.id {
                                store.classSchedule.removeCourse(id: id, for: day)
                            }
                            dismiss()
                        } label: {
                            Label("刪除課程", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(editing == nil ? "新增課程" : "編輯課程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        save()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let c = editing {
                    title = c.title
                    icon = c.icon
                    colorHex = c.colorHex
                    startDate = RingTimeHelpers.date(from: c.startMinute)
                    endDate = RingTimeHelpers.date(from: c.endMinute)
                    hpCost = c.hpCost
                    fpCost = c.fpCost
                }
            }
        }
    }

    private func save() {
        let start = RingTimeHelpers.snap(RingTimeHelpers.minute(from: startDate))
        var end = RingTimeHelpers.snap(RingTimeHelpers.minute(from: endDate))
        if end == start { end = (start + 10) % RingTimeHelpers.totalMinutes }

        var course = editing ?? ClassScheduleV2.CourseSlot(
            title: "", startMinute: start, endMinute: end
        )
        course.title = title.trimmingCharacters(in: .whitespaces)
        course.icon = icon
        course.colorHex = colorHex
        course.startMinute = start
        course.endMinute = end
        course.hpCost = hpCost
        course.fpCost = fpCost

        if editing != nil {
            store.classSchedule.updateCourse(course, for: day)
        } else {
            store.classSchedule.addCourse(course, for: day)
        }
    }
}
