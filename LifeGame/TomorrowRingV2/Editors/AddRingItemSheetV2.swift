import SwiftUI

// MARK: - AddRingItemSheetV2

/// Sheet for adding or editing a ring item. Used for both plan and actual rings.
struct AddRingItemSheetV2: View {
    @Environment(\.dismiss) private var dismiss

    let ring: DualRingCanvas.ActiveRing
    var editing: RingItemV2?
    var prefillStart: Int = 540
    var prefillEnd: Int = 600
    var onSave: (RingItemV2) -> Void

    // MARK: - Draft state

    @State private var title: String = ""
    @State private var icon: String = "circle.fill"
    @State private var colorHex: String = "5B9BD5"
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var hpCost: Int = 10
    @State private var fpCost: Int = 10

    private let iconOptions = [
        "circle.fill", "book", "laptopcomputer", "figure.walk",
        "fork.knife", "bed.double", "gamecontroller", "music.note",
        "pencil", "brain.head.profile", "dumbbell", "cup.and.saucer",
        "bus", "briefcase", "paintpalette", "heart.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("基本資訊") {
                    TextField("標題", text: $title)

                    // Icon picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(iconOptions, id: \.self) { sym in
                                Image(systemName: sym)
                                    .font(.title3)
                                    .foregroundStyle(sym == icon ? Color.accentColor : .secondary)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(sym == icon ? Color.accentColor.opacity(0.15) : Color.clear)
                                    )
                                    .onTapGesture { icon = sym }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Color picker
                    CompactPaletteColorPicker(selectedHex: $colorHex)
                }

                Section("時間") {
                    RingTimeField(title: "開始", date: $startDate)
                    RingTimeField(title: "結束", date: $endDate)

                    let dur = RingTimeHelpers.duration(
                        from: RingTimeHelpers.snap(RingTimeHelpers.minute(from: startDate)),
                        to: RingTimeHelpers.snap(RingTimeHelpers.minute(from: endDate))
                    )
                    Text("時長：\(dur / 60)h \(dur % 60)m")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("資源消耗") {
                    Stepper("HP 消耗：\(hpCost)", value: $hpCost, in: 0...100, step: 5)
                    Stepper("FP 消耗：\(fpCost)", value: $fpCost, in: 0...100, step: 5)
                }
            }
            .navigationTitle(editing == nil ? "新增時段" : "編輯時段")
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
                if let item = editing {
                    title = item.title
                    icon = item.icon
                    colorHex = item.colorHex
                    startDate = RingTimeHelpers.date(from: item.startMinute)
                    endDate = RingTimeHelpers.date(from: item.endMinute)
                    hpCost = item.hpCost
                    fpCost = item.fpCost
                } else {
                    startDate = RingTimeHelpers.date(from: prefillStart)
                    endDate = RingTimeHelpers.date(from: prefillEnd)
                }
            }
        }
    }

    private func save() {
        let start = RingTimeHelpers.snap(RingTimeHelpers.minute(from: startDate))
        var end = RingTimeHelpers.snap(RingTimeHelpers.minute(from: endDate))
        if end == start { end = (start + 10) % RingTimeHelpers.totalMinutes }

        var item = editing ?? RingItemV2(
            startMinute: start, endMinute: end,
            title: "", icon: icon, colorHex: colorHex
        )
        item.title = title.trimmingCharacters(in: .whitespaces)
        item.icon = icon
        item.colorHex = colorHex
        item.startMinute = start
        item.endMinute = end
        item.hpCost = hpCost
        item.fpCost = fpCost
        if editing == nil { item.source = .manual }

        onSave(item)
    }
}
