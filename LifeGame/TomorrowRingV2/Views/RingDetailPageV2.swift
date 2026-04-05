import SwiftUI

// MARK: - RingDetailPageV2

struct RingDetailPageV2: View {
    @EnvironmentObject private var store: TomorrowRingStore
    @EnvironmentObject private var fab: FabStore
    @EnvironmentObject private var theme: ThemeStore

    @State private var selectedItemID: UUID?
    @State private var editingItem: RingItemV2?
    @State private var showAddSheet = false
    @State private var showClassScheduleEditor = false
    @State private var addingToRing: DualRingCanvas.ActiveRing = .plan
    @State private var prefillStart: Int = 540
    @State private var prefillEnd: Int = 600

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > 700

            if isWide {
                // iPad: side-by-side
                HStack(spacing: 0) {
                    ringSection
                        .frame(width: geo.size.width * 0.55)
                    Divider()
                    ScrollView {
                        listSection
                    }
                }
            } else {
                // iPhone: vertical scroll
                ScrollView {
                    VStack(spacing: 16) {
                        ringSection
                            .frame(height: 360)
                        listSection
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 80)
                }
            }
        }
        .navigationTitle("時間圓環")
        .navigationBarTitleDisplayMode(.inline)

        // Switch FAB to tomorrowRing feature context
        .onAppear {
            fab.apply(context: .feature(.tomorrowRing))
            store.applyClassScheduleIfNeeded()
        }
        .onDisappear {
            fab.popActions()
        }

        // Listen to FAB routes
        .onChange(of: fab.route) { _, newRoute in
            switch newRoute {
            case .addRingItem:
                fab.route = nil
                addingToRing = .plan
                prefillStart = 540
                prefillEnd = 600
                showAddSheet = true
            case .editSchedule:
                fab.route = nil
                showClassScheduleEditor = true
            default:
                break
            }
        }

        .sheet(isPresented: $showAddSheet) {
            AddRingItemSheetV2(ring: addingToRing, prefillStart: prefillStart, prefillEnd: prefillEnd) { newItem in
                switch addingToRing {
                case .plan:
                    store.addPlanItem(newItem)
                case .actual:
                    store.addActualItem(newItem)
                }
            }
        }
        .sheet(item: $editingItem) { item in
            AddRingItemSheetV2(ring: addingToRing, editing: item) { updated in
                switch addingToRing {
                case .plan:
                    store.updatePlanItem(updated)
                case .actual:
                    if let idx = store.plan.actualItems.firstIndex(where: { $0.id == updated.id }) {
                        store.plan.actualItems[idx] = updated
                    }
                }
            }
        }
        .sheet(isPresented: $showClassScheduleEditor) {
            NavigationStack {
                ClassScheduleEditorV2()
                    .environmentObject(store)
                    .environmentObject(theme)
            }
        }
    }

    // MARK: - Ring Section

    private var ringSection: some View {
        DualRingCanvas(mode: .detail, selectedItemID: $selectedItemID) { ring, gapStart, gapEnd in
            addingToRing = ring
            prefillStart = gapStart
            prefillEnd = gapEnd
            showAddSheet = true
        }
        .padding()
    }

    // MARK: - List Section

    private var listSection: some View {
        VStack(spacing: 20) {
            // Plan ring list
            VStack(spacing: 8) {
                Text("內圈 · 預定行程")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)

                RingItemListV2(
                    items: store.plan.planItems,
                    ringLabel: "",
                    selectedItemID: $selectedItemID,
                    onEdit: { item in
                        addingToRing = .plan
                        editingItem = item
                    },
                    onDelete: { id in
                        store.removePlanItem(id: id)
                    }
                )
            }

            Divider()

            // Actual ring list
            VStack(spacing: 8) {
                HStack {
                    Text("外圈 · 實際執行")
                        .font(.headline)
                    Spacer()
                    Button {
                        store.initializeActualFromPlan()
                    } label: {
                        Label("從預定複製", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 12)

                RingItemListV2(
                    items: store.plan.actualItems,
                    ringLabel: "",
                    selectedItemID: $selectedItemID,
                    onEdit: { item in
                        addingToRing = .actual
                        editingItem = item
                    },
                    onDelete: { id in
                        store.removeActualItem(id: id)
                    }
                )
            }

            // HP/FP summary
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text("剩餘 \(store.plan.remainingHP) / \(store.plan.baseHP)")
                        .font(.caption)
                }
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("剩餘 \(store.plan.remainingFP) / \(store.plan.baseFP)")
                        .font(.caption)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
        }
    }
}
