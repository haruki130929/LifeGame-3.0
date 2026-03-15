import SwiftUI

/// 新增 / 編輯自訂切頁的表單
struct CustomTabEditorSheet: View {
    /// nil = 新增模式；非 nil = 編輯模式
    var editingTab: CustomTab?

    @EnvironmentObject private var customTabStore: CustomTabStore
    @Environment(\.dismiss) private var dismiss

    @State private var tabName: String = ""
    @State private var selectedCardTypes: [CardType] = []

    // 可選的卡片類型（排除 editCards）
    private let availableCardTypes: [CardType] = [
        .calendar, .todoQuadrant,
        .tomorrowRing, .bagRequired, .monthlyScoreCalendar
    ]

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                cardSelectionSection
                cardOrderSection
            }
            .navigationTitle(editingTab == nil ? "新增切頁" : "編輯切頁")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { saveAndDismiss() }
                        .disabled(tabName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            .onAppear {
                if let tab = editingTab {
                    tabName = tab.name
                    selectedCardTypes = tab.cardTypes
                }
            }
        }
    }

    // MARK: - 名稱

    private var nameSection: some View {
        Section("切頁名稱") {
            TextField("例如：學習、生活、工作", text: $tabName)
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

    // MARK: - Save

    private func saveAndDismiss() {
        let trimmedName = tabName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if var tab = editingTab {
            tab.name = trimmedName
            tab.cardTypes = selectedCardTypes
            customTabStore.update(tab)
        } else {
            let newTab = CustomTab(
                name: trimmedName,
                icon: "square.grid.2x2",
                cardTypes: selectedCardTypes
            )
            customTabStore.add(newTab)
        }
        dismiss()
    }
}
