import SwiftUI

struct DailyLogFormView: View {
    @Binding var entry: DailyLogEntry
    @EnvironmentObject private var moduleStore: QuestionModuleStore

    var body: some View {
        Form {
            ForEach(Array(moduleStore.enabledModules.enumerated()), id: \.element.id) { index, module in
                moduleSection(for: module, number: index + 1)
            }
        }
        .onAppear { moduleStore.reloadFromStorage() }
    }

    @ViewBuilder
    private func moduleSection(for module: DailyLogModule, number: Int) -> some View {
        let header = "\(number). \(module.displayTitle)"

        // 有自訂問題的模組（含內建），統一用動態渲染
        if let questions = module.questions, !questions.isEmpty {
            CustomModuleSectionView(module: module, answers: $entry.customAnswers, header: header)
        } else {
            // 未自訂的內建模組用硬編碼畫面
            switch module.kind {
            case .basic:
                BasicSectionView(entry: $entry, header: header)
            case .moodMental:
                MoodMentalSectionView(entry: $entry, header: header)
            case .moodChange:
                MoodChangeSectionView(entry: $entry, header: header)
            case .anxiety:
                AnxietySectionView(entry: $entry, header: header)
            case .impulse:
                ImpulseSectionView(entry: $entry, header: header)
            case .sleep:
                SleepSectionView(entry: $entry, header: header)
            case .studyFocus:
                StudyFocusSectionView(entry: $entry, header: header)
            case .body:
                BodySectionView(entry: $entry, header: header)
            case .observation:
                ObservationSectionView(entry: $entry, header: header)
            case .custom:
                CustomModuleSectionView(module: module, answers: $entry.customAnswers, header: header)
            }
        }
    }
}
