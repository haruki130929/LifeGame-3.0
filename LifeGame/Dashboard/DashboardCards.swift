import SwiftUI

struct DailyLogCard: View {
    let size: CardSize
    
    var body: some View {
        DashboardCardContainer {
            VStack(alignment: .leading, spacing: 10) {
                CardHeader(title: "每日紀錄", icon: "square.and.pencil")
                Text(size == .small ? "快速記錄" : "快速記錄今天")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct EditCardsCard: View {
    let slot: TimeSlot
    let size: CardSize
    
    var body: some View {
        DashboardCardContainer {
            VStack(alignment: .leading, spacing: 10) {
                CardHeader(title: "編輯卡片", icon: "square.grid.2x2")
                Text("時段：\(slot.rawValue)")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
