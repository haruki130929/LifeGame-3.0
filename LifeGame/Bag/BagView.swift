import SwiftUI
import SwiftData

// MARK: - Seed 預設書包物品

enum BagSeeder {
    static let defaults: [(name: String, icon: String, isRequired: Bool)] = [
        ("錢包", "wallet.bifold", true),
        ("鑰匙", "key", true),
        ("耳機", "airpods.pro", true),
        ("充電線", "cable.connector", false),
        ("行動電源", "bolt.batteryblock", false),
        ("水壺", "waterbottle.fill", true),
        ("筆袋", "applepencil", true),
        ("手帳本", "book", false),
        ("課本／講義", "books.vertical.fill", false)
    ]

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let desc = FetchDescriptor<BagItemModel>()
        let existing = (try? context.fetch(desc)) ?? []

        // 修正舊 icon（bag.fill → waterbottle.fill）
        for item in existing where item.name == "水壺" && item.icon == "bag.fill" {
            item.icon = "waterbottle.fill"
        }

        guard existing.isEmpty else {
            try? context.save()
            return
        }
        for d in defaults {
            context.insert(BagItemModel(name: d.name, icon: d.icon, isRequired: d.isRequired, isChecked: false))
        }
        try? context.save()
    }
}

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
    @EnvironmentObject private var fab: FabStore
    @Query(sort: \BagItemModel.name) private var items: [BagItemModel]

    @State private var showAdd = false
    @State private var editingItem: BagItemModel? = nil
    @State private var isEditMode = false
    
    // 預設物品改由 BagSeeder 統一管理
    
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 120), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    BagItemCard(item: item) {
                        if isEditMode {
                            editingItem = item
                        } else {
                            toggle(item)
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        if isEditMode {
                            Button { deleteItem(item) } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.red)
                            }
                            .offset(x: -6, y: -6)
                        }
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
            fab.apply(context: .feature(.bagRequired))
        }
        .onChange(of: fab.route) {
            guard let route = fab.route else { return }
            switch route {
            case .addBagItem:
                showAdd = true
                fab.route = nil
            case .bagEditMode:
                isEditMode.toggle()
                fab.route = nil
            default:
                break
            }
        }
    }
    
    // MARK: - Actions (SwiftData)
    
    private func seedIfNeeded() {
        BagSeeder.seedIfNeeded(context: context)
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
    
}
