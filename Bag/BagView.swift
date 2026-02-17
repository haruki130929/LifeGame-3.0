import SwiftUI

// MARK: - Card

struct BagItemCard: View {
    let item: BagItem
    let isChecked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(isChecked ? .green : .primary)
                    
                    Text(item.name)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding(12)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(alignment: .topLeading) {
                    if item.isRequired {
                        Image(systemName: "pin.circle")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .padding(8)
                    }
                }
                
                if isChecked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Main View

struct Bag_BackpackChecklistView: View {
    
    @AppStorage("BagItems_v2") private var itemsData: Data = Data()
    @AppStorage("bag_checked_ids_v2") private var checkedData: Data = Data()
    
    @State private var showAdd = false
    @State private var editingItem: BagItem? = nil
    @State private var showResetConfirm = false
    
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
    
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 120), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    BagItemCard(
                        item: item,
                        isChecked: checkedIDs.contains(item.id)
                    ) {
                        toggle(item.id)
                    }
                    .contextMenu {
                        Button { editingItem = item } label: {
                            Label("編輯", systemImage: "pencil")
                        }
                        
                        Button { toggleRequired(item) } label: {
                            Label(item.isRequired ? "取消必帶" : "設為必帶", systemImage: "pin.circle")
                        }
                        
                        Button(role: .destructive) { deleteItem(item) } label: {
                            Label("刪除", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("整理書包")
        .navigationBarTitleDisplayMode(.inline)
        
        // ✅ 重要：右上角 + 不要放，交給 FAB
        .toolbar { }
        
        // 左下角「重設」＋右下角「完成(清空勾選)」
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    showResetConfirm = true
                } label: {
                    Label("重設", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button {
                    clearAllChecked()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        
        .confirmationDialog(
            "要重設書包物品嗎？",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("重設", role: .destructive) { resetToDefault() }
            Button("取消", role: .cancel) { }
        }
        
        // 新增
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                BagItemEditorView(mode: .add) { result in
                    var list = items
                    list.append(result)
                    items = list
                }
            }
        }
        
        // 編輯
        .sheet(item: $editingItem) { item in
            NavigationStack {
                BagItemEditorView(mode: .edit(item)) { updated in
                    updateItem(updated)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func clearAllChecked() {
        checkedIDs = []
    }
    
    private func resetToDefault() {
        items = defaultItems
        checkedIDs = []
        editingItem = nil
        showAdd = false
    }
    
    private func toggle(_ id: UUID) {
        var s = checkedIDs
        if s.contains(id) { s.remove(id) } else { s.insert(id) }
        checkedIDs = s
    }
    
    private func toggleRequired(_ item: BagItem) {
        var list = items
        if let idx = list.firstIndex(where: { $0.id == item.id }) {
            list[idx].isRequired.toggle()
            items = list
        }
    }
    
    private func deleteItem(_ item: BagItem) {
        var list = items
        list.removeAll { $0.id == item.id }
        items = list
        
        var s = checkedIDs
        s.remove(item.id)
        checkedIDs = s
    }
    
    private func updateItem(_ updated: BagItem) {
        var list = items
        if let idx = list.firstIndex(where: { $0.id == updated.id }) {
            list[idx] = updated
            items = list
        }
    }
    
    // 先留著，之後如果要做「全勾」再用
    private func markAllChecked() {
        checkedIDs = Set(items.map { $0.id })
    }
}
