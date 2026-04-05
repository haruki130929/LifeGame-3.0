import SwiftUI

/// 在功能頁首次出現時自動彈出教學 sheet
struct FeatureTutorialModifier: ViewModifier {
    let featureKey: FeatureTutorialTracker.FeatureKey
    @Environment(FeatureTutorialTracker.self) private var tutorialTracker
    @EnvironmentObject private var theme: ThemeStore
    @State private var showTutorial = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                if tutorialTracker.shouldShowTutorial(for: featureKey) {
                    // 延遲一點讓頁面先渲染完
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showTutorial = true
                    }
                }
            }
            .sheet(isPresented: $showTutorial) {
                if let item = TutorialData.item(for: featureKey) {
                    NavigationStack {
                        TutorialDetailView(item: item)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("知道了") {
                                        showTutorial = false
                                    }
                                }
                            }
                    }
                    .environmentObject(theme)  // sheet 重建環境，需顯式傳入
                    .presentationDetents([.medium, .large])
                }
            }
            .onChange(of: showTutorial) { _, newValue in
                if !newValue {
                    tutorialTracker.markAsSeen(featureKey)
                }
            }
    }
}

extension View {
    /// 首次進入此功能頁時自動顯示教學
    func featureTutorial(_ key: FeatureTutorialTracker.FeatureKey) -> some View {
        modifier(FeatureTutorialModifier(featureKey: key))
    }
}
