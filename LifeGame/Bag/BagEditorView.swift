// File: Bag/BagEditorViews.swift
import SwiftUI
import SwiftData

struct BagItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context   // ✅ 新增：SwiftData context
    
    let mode: BagItemEditorMode
    var onDone: (BagItem) -> Void
    
    @State private var name: String = ""
    @State private var icon: String = "backpack"
    @State private var isRequired: Bool = false
    
    @State private var showIconPicker = false
    @FocusState private var nameFocused: Bool
    
    var body: some View {
        Form {
            Section("物品") {
                TextField("物品名稱", text: $name)
                    .focused($nameFocused)
            }
            
            Section("圖示") {
                Button { showIconPicker = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .font(.title2)
                            .frame(width: 32)

                        Spacer()

                        Text("選擇")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("標記") {
                Toggle("必帶", isOn: $isRequired)
            }
            
            Section {
                Text("圖示直接在分類裡挑，必要時再用搜尋。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if case .edit(let item) = mode {
                name = item.name
                icon = item.icon
                isRequired = item.isRequired
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                nameFocused = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let result: BagItem
                    switch mode {
                    case .add:
                        result = BagItem(name: trimmed, icon: icon, isRequired: isRequired)
                    case .edit(let old):
                        result = BagItem(id: old.id, name: trimmed, icon: icon, isRequired: isRequired)
                    }
                    
                    // ✅ 只改儲存：把結果寫進 SwiftData
                    persistToSwiftData(result)
                    
                    // ✅ 保留原本行為：仍然回傳給呼叫端（避免其他檔案現在就要全改）
                    onDone(result)
                    
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .sheet(isPresented: $showIconPicker) {
            NavigationStack {
                IconPickerView(selected: $icon)
            }
        }
    }
    
    // MARK: - SwiftData persistence (storage only)
    private func persistToSwiftData(_ item: BagItem) {
        // 用 id 做 upsert：有就更新，沒有就新增（避免重複）
        let id = item.id
        let predicate = #Predicate<BagItemModel> { $0.id == id }
        let descriptor = FetchDescriptor<BagItemModel>(predicate: predicate)
        
        if let existing = try? context.fetch(descriptor).first {
            existing.name = item.name
            existing.icon = item.icon
            existing.isRequired = item.isRequired
        } else {
            let model = BagItemModel(id: item.id, name: item.name, icon: item.icon, isRequired: item.isRequired)
            context.insert(model)
        }
        
        context.safeSave()
    }
}

struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: String
    
    @State private var category: IconCategory = .daily
    @State private var query: String = ""
    
    private var filteredIcons: [String] {
        let base = category.icons
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return base }
        return base.filter { $0.localizedCaseInsensitiveContains(q) }
    }
    
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 64), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Picker("分類", selection: $category) {
                    ForEach(IconCategory.allCases) { c in
                        Text(c.rawValue).tag(c)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                TextField("在此分類內搜尋（可空白）", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredIcons, id: \.self) { icon in
                        Button {
                            selected = icon
                            dismiss()
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                VStack(spacing: 8) {
                                    Image(systemName: icon)
                                        .font(.system(size: 26, weight: .semibold))
                                        .frame(height: 30)
                                }
                                .frame(maxWidth: .infinity, minHeight: 72)
                                .padding(10)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                
                                if icon == selected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .padding(6)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("選擇圖示")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("關閉") { dismiss() }
            }
        }
    }
}
