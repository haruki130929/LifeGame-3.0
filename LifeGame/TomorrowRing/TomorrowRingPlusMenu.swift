import SwiftUI

struct TomorrowRingPlusMenu: View {
    @Binding var plan: TomorrowRingPlan
    
    var body: some View {
        Menu {
            Button {
                addDefaultSlot()
            } label: {
                Label("新增時段", systemImage: "plus")
            }
            
            // 這裡可以依照善甯主頁 + 的選單內容，繼續加項目
            Button {
                // 例：快速建立範本
            } label: {
                Label("套用範本", systemImage: "sparkles")
            }
            
        } label: {
            PlusFloatingButton()
        }
    }
    
    private func addDefaultSlot() {
        // ✅ 先給一個合理預設：新增 1 小時（可再改成善甯想要的）
        let new = RingItem(
            id: UUID(),
            slot: .morning,          // ⭐ 依你原本的 enum 改（morning / afternoon / night）
            startMinute: 9 * 60,
            endMinute: 10 * 60,
            title: String(localized: "新時段"),
            icon: "clock",           // SF Symbol
            colorHex: "4DA3FF",
            hpCost: 0,
            fpCost: 0
        )
        plan.items.append(new)
    }
}

private struct PlusFloatingButton: View {
    var body: some View {
        Image(systemName: "plus")
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.primary)
            .frame(width: 52, height: 52)
            .background(.thinMaterial, in: Circle())
            .overlay(
                Circle().stroke(.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(radius: 10, y: 6)
            .contentShape(Circle())
            .accessibilityLabel("新增時段")
    }
}
