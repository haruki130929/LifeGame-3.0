import SwiftUI

struct FinanceHubView: View {
    @StateObject var wishStore: WishStore
    @ObservedObject var ledgerStore: LedgerStore
    
    @State private var tab: Int = 0
    
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
