import SwiftUI

struct MandalaChartScreen: View {

    @EnvironmentObject private var store: MandalaStore
    @EnvironmentObject private var fab: FabStore
    @State private var isEditMode = false

    var body: some View {
        VStack(spacing: 0) {
            MandalaChartView(store: store, isEditMode: $isEditMode)
                .id(store.colorRevision)

            // 多頁切換：只在有多個圖表時顯示
            if store.documents.count > 1 {
                pageIndicator
                    .padding(.vertical, 8)
            }
        }
        .navigationTitle(store.doc.name)
        .onAppear {
            fab.apply(context: .feature(.mandala))
        }
        .onChange(of: fab.route) {
            guard let route = fab.route else { return }
            switch route {
            case .addMandalaChart:
                store.addDocument()
                fab.route = nil
            case .mandalaEditMode:
                isEditMode.toggle()
                fab.route = nil
            default:
                break
            }
        }
    }

    // MARK: - 底部頁面指示器

    private var pageIndicator: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(store.documents.enumerated()), id: \.element.id) { index, doc in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.currentIndex = index
                        }
                    } label: {
                        Text(doc.name)
                            .font(.caption)
                            .fontWeight(store.currentIndex == index ? .bold : .regular)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(store.currentIndex == index
                                          ? Color.accentColor.opacity(0.2)
                                          : Color(UIColor.tertiarySystemFill))
                            )
                            .foregroundStyle(store.currentIndex == index ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
