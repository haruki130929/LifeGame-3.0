import SwiftUI

struct MandalaChartScreen: View {
    
    @StateObject private var store = MandalaStore()
    
    var body: some View {
        MandalaChartView(store: store)
            .navigationTitle("曼陀羅圖表")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("清空") {
                        store.reset()
                    }
                }
            }
    }
}
