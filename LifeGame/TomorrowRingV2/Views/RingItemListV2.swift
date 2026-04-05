import SwiftUI

// MARK: - RingItemListV2

struct RingItemListV2: View {
    let items: [RingItemV2]
    let ringLabel: String
    @Binding var selectedItemID: UUID?
    var onEdit: ((RingItemV2) -> Void)?
    var onDelete: ((UUID) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ringLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)

            if items.isEmpty {
                Text("尚無時段")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                ForEach(items.sorted { $0.startMinute < $1.startMinute }) { item in
                    RingItemRowV2(
                        item: item,
                        isSelected: item.id == selectedItemID,
                        onTap: {
                            withAnimation(.spring(response: 0.25)) {
                                selectedItemID = (selectedItemID == item.id) ? nil : item.id
                            }
                        }
                    )
                    .contextMenu {
                        Button {
                            onEdit?(item)
                        } label: {
                            Label("編輯", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            onDelete?(item.id)
                        } label: {
                            Label("刪除", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDelete?(item.id)
                        } label: {
                            Label("刪除", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}
