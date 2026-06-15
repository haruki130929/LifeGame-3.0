import SwiftUI

/// 編輯某個時段的卡片配置
struct SlotCardEditorSheet: View {
    let slot: TimeSlot
    @ObservedObject var slotCardStore: SlotCardConfigStore
    var selectedTab: TabSelection? = nil
    var onDeleteTab: (() -> Void)? = nil

    @EnvironmentObject private var timeSlotNameStore: TimeSlotNameStore
    @EnvironmentObject private var customTabStore: CustomTabStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItems: [CardItem] = []
    @State private var showDeleteConfirmation = false

    // 可選的卡片類型
    private let availableCardTypes: [CardType] = [
        .calendar, .todoQuadrant,
        .tomorrowRing, .bagRequired, .monthlyScoreCalendar,
        .ganttChart, .copingNotes
    ]

    var body: some View {
        NavigationStack {
            Form {
                cardSelectionSection
                cardOrderSection
                deleteTabSection
            }
            .navigationTitle("編輯「\(timeSlotNameStore.displayName(for: slot))」卡片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { saveAndDismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton().environment(\.locale, Locale(identifier: "zh-Hant"))
                }
            }
            .onAppear {
                selectedItems = slotCardStore.items(for: slot)
            }
        }
    }

    // MARK: - 卡片選擇

    private var cardSelectionSection: some View {
        Section("選擇要顯示的卡片") {
            ForEach(availableCardTypes) { cardType in
                cardToggleRow(cardType)
            }
        }
    }

    private func cardToggleRow(_ cardType: CardType) -> some View {
        let isOn = selectedItems.contains { $0.type == cardType }
        return Button {
            if isOn {
                selectedItems.removeAll { $0.type == cardType }
            } else {
                selectedItems.append(CardItem(type: cardType, size: cardType.defaultSize))
            }
        } label: {
            HStack {
                Image(systemName: cardType.icon)
                    .frame(width: 24)
                Text(cardType.title)
                Spacer()
                if isOn {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 已選卡片排序

    @ViewBuilder
    private var cardOrderSection: some View {
        if !selectedItems.isEmpty {
            Section {
                ForEach(selectedItems) { item in
                    HStack {
                        Label(item.type.title, systemImage: item.type.icon)
                        Spacer()
                        Picker("", selection: sizeBinding(for: item)) {
                            Text("小").tag(CardSize.small)
                            Text("中").tag(CardSize.medium)
                            Text("大").tag(CardSize.large)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 150)
                    }
                }
                .onMove { from, to in
                    selectedItems.move(fromOffsets: from, toOffset: to)
                }
            } header: {
                Text("卡片大小與順序（可拖曳排序）")
            } footer: {
                Text("大＝整排、中＝半排、小＝一格（僅 iPad 版面）")
            }
        }
    }

    private func sizeBinding(for item: CardItem) -> Binding<CardSize> {
        Binding(
            get: { selectedItems.first { $0.id == item.id }?.size ?? .medium },
            set: { newSize in
                if let idx = selectedItems.firstIndex(where: { $0.id == item.id }) {
                    selectedItems[idx].size = newSize
                }
            }
        )
    }

    // MARK: - 刪除切頁

    @ViewBuilder
    private var deleteTabSection: some View {
        if let selectedTab, case .tab(let tabId) = selectedTab,
           customTabStore.tabs.count > 1 {
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Label("刪除此切頁", systemImage: "trash")
                        Spacer()
                    }
                }
            }
            .confirmationDialog("確定要刪除此切頁嗎？刪除後無法復原。", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("刪除", role: .destructive) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDeleteTab?()
                    }
                }
                Button("取消", role: .cancel) {}
            }
        }
    }

    // MARK: - Save

    private func saveAndDismiss() {
        slotCardStore.setItems(selectedItems, for: slot)
        dismiss()
    }
}
