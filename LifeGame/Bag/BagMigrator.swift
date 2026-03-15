import Foundation
import SwiftData

enum BagMigrationFlags {
    static let didMigrateBagV2ToSwiftData = "migrate.didMigrateBagV2ToSwiftData.v1"
}

@MainActor
final class BagMigrator {
    private let context: ModelContext
    
    // 舊資料的 key（你原本 AppStorage 用的）
    private let itemsKey = "BagItems_v2"
    private let checkedKey = "bag_checked_ids_v2"
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func migrateIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: BagMigrationFlags.didMigrateBagV2ToSwiftData) == false else {
            return
        }
        
        // 1) 讀舊資料
        let itemsData = defaults.data(forKey: itemsKey) ?? Data()
        let checkedData = defaults.data(forKey: checkedKey) ?? Data()
        
        let oldItems: [BagItem] = bag_decode([BagItem].self, from: itemsData) ?? []
        let oldChecked: Set<UUID> = bag_decode(Set<UUID>.self, from: checkedData) ?? []
        
        // 2) 如果舊資料是空的，就不匯入（交給 seed）
        if oldItems.isEmpty {
            defaults.set(true, forKey: BagMigrationFlags.didMigrateBagV2ToSwiftData)
            return
        }
        
        // 3) 匯入到 SwiftData（upsert by id）
        for it in oldItems {
            upsert(item: it, isChecked: oldChecked.contains(it.id))
        }
        
        context.safeSave()
        
        // 4) 打旗標：避免下次重複匯入
        defaults.set(true, forKey: BagMigrationFlags.didMigrateBagV2ToSwiftData)
        
        // （可選）不建議立刻清掉，先保留以防萬一
        // defaults.removeObject(forKey: itemsKey)
        // defaults.removeObject(forKey: checkedKey)
        
        debugLog("✅ Bag migrate done. count=\(oldItems.count)")
    }
    
    private func upsert(item: BagItem, isChecked: Bool) {
        let id = item.id
        let predicate = #Predicate<BagItemModel> { $0.id == id }
        let desc = FetchDescriptor<BagItemModel>(predicate: predicate)
        
        if let existing = try? context.fetch(desc).first {
            existing.name = item.name
            existing.icon = item.icon
            existing.isRequired = item.isRequired
            existing.isChecked = isChecked
        } else {
            context.insert(
                BagItemModel(
                    id: item.id,
                    name: item.name,
                    icon: item.icon,
                    isRequired: item.isRequired,
                    isChecked: isChecked
                )
            )
        }
    }
}
