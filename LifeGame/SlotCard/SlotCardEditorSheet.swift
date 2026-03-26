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

    @State private var selectedCardTypes: [CardType] = []
    @State private var showDeleteConfirmation = false

    // 可選的卡片類型
    private let availableCardTypes: [CardType] = [
        .calendar, .todoQuadrant,
        .tomorrowRing, .bagRequired, .monthlyScoreCalendar
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
                selectedCardTypes = slotCardStore.items(for: slot).map { $0.type }
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
        let isOn = selectedCardTypes.contains(cardType)
        return Button {
            if isOn {
                selectedCardTypes.removeAll { $0 == cardType }
            } else {
                selectedCardTypes.append(cardType)
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
        if !selectedCardTypes.isEmpty {
            Section("卡片順序（可拖曳排序）") {
                ForEach(selectedCardTypes, id: \.self) { cardType in
                    Label(cardType.title, systemImage: cardType.icon)
                }
                .onMove { from, to in
                    selectedCardTypes.move(fromOffsets: from, toOffset: to)
                }
            }
        }
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
        let items = selectedCardTypes.map { CardItem(type: $0, size: $0.defaultSize) }
        slotCardStore.setItems(items, for: slot)
        dismiss()
    }
}
