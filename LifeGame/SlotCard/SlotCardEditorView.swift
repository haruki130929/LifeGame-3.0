import SwiftUI

struct SlotCardEditorView: View {
    @ObservedObject var store: SlotCardConfigStore
    @EnvironmentObject private var timeSlotNameStore: TimeSlotNameStore
    @State private var slot: TimeSlot = .beforeLeave

    var body: some View {
        List {
            Section {
                Picker("時段", selection: $slot) {
                    ForEach(TimeSlot.allCases) { s in
                        Text(timeSlotNameStore.displayName(for: s)).tag(s)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("這個時段要顯示的卡片（可拖曳排序、可刪除）") {
                ForEach(store.items(for: slot)) { item in
                    HStack {
                        Image(systemName: item.type.icon)
                        Text(item.type.title)
                        Spacer()
                        Text(item.size.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onMove { from, to in
                    var items = store.items(for: slot)
                    items.move(fromOffsets: from, toOffset: to)
                    store.setItems(items, for: slot)
                }
                .onDelete { indexSet in
                    var items = store.items(for: slot)
                    
                    // 不讓 editCards 被刪掉
                    let removing = indexSet.map { items[$0] }
                    if removing.contains(where: { $0.type == .editCards }) { return }
                    
                    items.remove(atOffsets: indexSet)
                    
                    // ✅ 補 tomorrowRing
                    if !items.contains(where: { $0.type == .tomorrowRing }) {
                        items.insert(CardItem(type: .tomorrowRing, size: .large), at: 0)
                    }
                    
                    // ✅ 補 bagRequired（整理書包：只顯示必帶）
                    if !items.contains(where: { $0.type == .bagRequired }) {
                        // 建議放在 tomorrowRing 後面，視覺順序比較合理
                        let insertIndex = min(1, items.count)
                        items.insert(CardItem(type: .bagRequired, size: .medium), at: insertIndex)
                    }
                    
                    store.setItems(items, for: slot)
                }
            }
        }
        .navigationTitle("編輯卡片")
        .toolbar { EditButton() }
    }
}
