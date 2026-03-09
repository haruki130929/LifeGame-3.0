import SwiftUI

struct FinanceHubView: View {
    @ObservedObject var wishStore: WishStore    // ✅ @StateObject → @ObservedObject
    @ObservedObject var ledgerStore: LedgerStore
    
    @State private var tab: Int
    
    // ✅ 可以指定預設 tab（0=願望, 1=記帳）
    init(wishStore: WishStore, ledgerStore: LedgerStore, defaultTab: Int = 0) {
        self.wishStore = wishStore
        self.ledgerStore = ledgerStore
        self._tab = State(initialValue: defaultTab)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Picker("", selection: $tab) {
                Text("慾望清單").tag(0)
                Text("記帳").tag(1)
            }
            .pickerStyle(.segmented)
            
            if tab == 0 {
                WishListView(store: wishStore, ledgerStore: ledgerStore)
            } else {
                LedgerView(store: ledgerStore)
            }
        }
        .padding()
        .navigationTitle("財務")
    }
}
