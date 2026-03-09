import SwiftUI
import SwiftData

// MARK: - Card

struct BagItemCard: View {
    let item: BagItemModel
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(item.isChecked ? .green : .primary)
                    
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
                
                if item.isChecked {
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
    
    @Environment(\.modelContext) private var context
    @Query(sort: \BagItemModel.name) private var items: [BagItemModel]
    
    @State private var showAdd = false
    @State private var editingItem: BagItemModel? = nil
    @State private var showResetConfirm = false
    
    // ✅ 預設物品：第一次資料庫是空的時候會自動灌進去
    private let defaultItems: [(name: String, icon: String, isRequired: Bool)] = [
        ("錢包", "wallet.pass", true),
        ("鑰匙", "key", true),
        ("耳機", "headphones", true),
        ("充電線", "cable.connector", false),
        ("行動電源", "battery.100.bolt", false),
        ("水壺", "waterbottle", true),
        ("筆袋", "pencil", true),
        ("手帳本", "book", false),
        ("課本／講義", "books.vertical", false)
    ]
    
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 120), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    BagItemCard(item: item) {
                        toggle(item)
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
                BagItemEditorView(mode: .add) { _ in
                    // ✅ Editor 內部已經寫入 SwiftData（我們前面改過）
                    // 這裡不需要再改動任何資料
                }
            }
        }
        
        // 編輯
        .sheet(item: $editingItem) { item in
            NavigationStack {
                // ✅ 這裡仍然走你原本的 Editor（UI 不變）
                // 但 mode 要用 BagItem（舊 struct），所以我們做一個轉換
                BagItemEditorView(
                    mode: .edit(BagItem(id: item.id, name: item.name, icon: item.icon, isRequired: item.isRequired))
                ) { _ in
                    // ✅ Editor 內部會 upsert 到 SwiftData
                }
            }
        }
        
        // ✅ 第一次進來資料庫是空的，就灌預設物品（只動儲存，不動 UI）
        .onAppear {
            seedIfNeeded()
        }
    }
    
    // MARK: - Actions (SwiftData)
    
    private func seedIfNeeded() {
        guard items.isEmpty else { return }
        for d in defaultItems {
            context.insert(BagItemModel(name: d.name, icon: d.icon, isRequired: d.isRequired, isChecked: false))
        }
        try? context.save()
    }
    
    private func clearAllChecked() {
        for item in items {
            item.isChecked = false
        }
        try? context.save()
    }
    
    private func resetToDefault() {
        // 刪光 → 灌預設 → 全取消勾選
        for item in items {
            context.delete(item)
        }
        for d in defaultItems {
            context.insert(BagItemModel(name: d.name, icon: d.icon, isRequired: d.isRequired, isChecked: false))
        }
        try? context.save()
        
        editingItem = nil
        showAdd = false
    }
    
    private func toggle(_ item: BagItemModel) {
        item.isChecked.toggle()
        try? context.save()
    }
    
    private func toggleRequired(_ item: BagItemModel) {
        item.isRequired.toggle()
        try? context.save()
    }
    
    private func deleteItem(_ item: BagItemModel) {
        context.delete(item)
        try? context.save()
    }
    
    // 先留著，之後如果要做「全勾」再用
    private func markAllChecked() {
        for item in items {
            item.isChecked = true
        }
        try? context.save()
    }
}
