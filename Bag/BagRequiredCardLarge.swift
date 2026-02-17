import SwiftUI

/// 主頁用：Large 卡片（只顯示「必帶」）
/// - 點一下圖案：變綠＋打勾（跟 Bag_BackpackChecklistView 共用同一份 checkedIDs）
/// - 點右上角：進入「整理書包」頁面
struct BagRequiredCardLarge: View {
    let size: CardSize
    
    @AppStorage("BagItems_v2") private var itemsData: Data = Data()
    @AppStorage("bag_checked_ids_v2") private var checkedData: Data = Data()
    
    private let defaultItems: [BagItem] = [
        BagItem(name: "錢包", icon: "wallet.pass", isRequired: true),
        BagItem(name: "鑰匙", icon: "key", isRequired: true),
        BagItem(name: "耳機", icon: "headphones", isRequired: true),
        BagItem(name: "充電線", icon: "cable.connector", isRequired: false),
        BagItem(name: "行動電源", icon: "battery.100.bolt", isRequired: false),
        BagItem(name: "水壺", icon: "waterbottle", isRequired: true),
        BagItem(name: "筆袋", icon: "pencil", isRequired: true),
        BagItem(name: "手帳本", icon: "book", isRequired: false),
        BagItem(name: "課本／講義", icon: "books.vertical", isRequired: false)
    ]
    
    private var items: [BagItem] {
        get { bag_decode([BagItem].self, from: itemsData) ?? defaultItems }
        nonmutating set { itemsData = bag_encode(newValue) ?? Data() }
    }
    
    private var checkedIDs: Set<UUID> {
        get { bag_decode(Set<UUID>.self, from: checkedData) ?? [] }
        nonmutating set { checkedData = bag_encode(newValue) ?? Data() }
    }
    
    private var requiredItems: [BagItem] {
        items.filter { $0.isRequired }
    }
    
    // Large 版用 2 列（iPad 上看起來接近頁面卡片）
    private let cols: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        DashboardCardContainer {
            VStack(alignment: .leading, spacing: 12) {
                
                // Header
                HStack(spacing: 10) {
                    Image(systemName: "backpack")
                        .font(.headline)
                    
                    Text("收拾書包")
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Icons
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(requiredItems) { item in
                        RequiredIconChip(
                            icon: item.icon,
                            name: item.name,
                            isChecked: checkedIDs.contains(item.id)
                        ) {
                            toggle(item.id)
                        }
                    }
                }
                
                // Footer line
                HStack {
                    Text("必帶 \(requiredItems.count) 樣")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    let done = requiredItems.filter { checkedIDs.contains($0.id) }.count
                    Text("\(done)/\(requiredItems.count)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .onAppear {
            // 第一次進來：把預設清單存起來（跟 Bag_BackpackChecklistView 一樣）
            if bag_decode([BagItem].self, from: itemsData) == nil {
                items = defaultItems
            }
        }
    }
    
    private func toggle(_ id: UUID) {
        var s = checkedIDs
        if s.contains(id) { s.remove(id) } else { s.insert(id) }
        checkedIDs = s
    }
}

private struct RequiredIconChip: View {
    let icon: String
    let name: String
    let isChecked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isChecked ? .green : .primary)
                        .frame(height: 26)
                    
                    Text(name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, minHeight: 64)
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(isChecked ? 0.14 : 0.06), lineWidth: 1)
                )
                
                if isChecked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
