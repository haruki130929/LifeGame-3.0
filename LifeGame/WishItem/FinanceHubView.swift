import SwiftUI

struct FinanceHubView: View {
    @ObservedObject var wishStore: WishStore
    @ObservedObject var ledgerStore: LedgerStore

    @EnvironmentObject private var fab: FabStore

    @State private var tab: Int

    // FAB 觸發的 sheet
    @State private var showAddWish = false
    @State private var showAddLedger = false
    @State private var showLedgerChart = false
    @State private var wishEditMode: EditMode = .inactive

    init(wishStore: WishStore, ledgerStore: LedgerStore, defaultTab: Int = 0) {
        self.wishStore = wishStore
        self.ledgerStore = ledgerStore
        self._tab = State(initialValue: defaultTab)
    }

    var body: some View {
        VStack(spacing: 12) {
            Picker("", selection: $tab) {
                Text("願望清單").tag(0)
                Text("記帳").tag(1)
            }
            .pickerStyle(.segmented)

            if tab == 0 {
                WishListView(store: wishStore, ledgerStore: ledgerStore)
                    .environment(\.editMode, $wishEditMode)
            } else {
                LedgerView(store: ledgerStore)
            }
        }
        .padding()
        .navigationTitle("財務")
        .onAppear { applyFabContext() }
        .onDisappear { fab.popActions() }
        .onChange(of: tab) { _, _ in
            wishEditMode = .inactive
            applyFabContext()
        }
        .onChange(of: fab.route) {
            guard let route = fab.route else { return }
            switch route {
            case .addWish:
                showAddWish = true
                fab.route = nil
            case .editWishList:
                withAnimation {
                    wishEditMode = (wishEditMode == .active) ? .inactive : .active
                }
                fab.route = nil
            case .addLedgerEntry:
                showAddLedger = true
                fab.route = nil
            case .viewLedgerChart:
                showLedgerChart = true
                fab.route = nil
            default:
                break
            }
        }
        .sheet(isPresented: $showAddWish) {
            AddWishSheet(store: wishStore)
        }
        .sheet(isPresented: $showAddLedger) {
            AddLedgerEntrySheet(store: ledgerStore)
        }
        .sheet(isPresented: $showLedgerChart) {
            LedgerChartSheet(store: ledgerStore)
        }
        .featureTutorial(.finance)
    }

    private func applyFabContext() {
        fab.apply(context: .feature(tab == 0 ? .wish : .ledger))
    }
}
